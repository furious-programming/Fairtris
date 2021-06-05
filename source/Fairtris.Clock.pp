unit Fairtris.Clock;

{$MODE OBJFPC}{$LONGSTRINGS ON}

interface

uses
  Windows,
  MMsystem,
  Fairtris.Classes;


type
  TClockFrameRate = specialize TCustomState<Integer>;
  TClockFrameLoad = specialize TCustomState<Integer>;


type
  TClock = class(TObject)
  private
    FTimerPeriod: Integer;
  private
    FTicksPerSecond: Int64;
    FTicksPerFrame: Int64;
  private
    FFrameTicksBegin: Int64;
    FFrameTicksEnd: Int64;
    FFrameTicksNext: Int64;
  private
    FFrameIndex: Integer;
  private
    FFrameRate: TClockFrameRate;
    FFrameLoad: TClockFrameLoad;
  private
    FFrameRateTank: Integer;
    FFrameRateSecond: Integer;
    FFrameRateLimit: Integer;
  private
    FFrameLoadTank: Integer;
  private
    procedure SetFrameRateLimit(AFrameRateLimit: Integer);
  private
    function GetCounterFrequency(): Int64;
    function GetCounterValue(): Int64;
  private
    procedure InitSystemTimerPeriod();
    procedure DoneSystemTimerPeriod();
  private
    procedure InitCounters();
    procedure DoneCounters();
  private
    procedure InitFrameRate();
    procedure InitTicks();
  private
    procedure UpdateFrameRate();
    procedure UpdateFrameLoad();
  public
    constructor Create();
    destructor Destroy(); override;
  public
    procedure Initialize();
  public
    procedure UpdateFrameBegin();
    procedure UpdateFrameEnd();
    procedure UpdateFrameAlign();
  public
    property FrameRateLimit: Integer read FFrameRateLimit write SetFrameRateLimit;
  public
    property FrameRate: TClockFrameRate read FFrameRate;
    property FrameLoad: TClockFrameLoad read FFrameLoad;
  end;


var
  Clock: TClock;


implementation

uses
  Math,
  SysUtils,
  DateUtils,
  Fairtris.Constants;


constructor TClock.Create();
begin
  InitSystemTimerPeriod();

  InitCounters();
  InitFrameRate();
  InitTicks();
end;


destructor TClock.Destroy();
begin
  DoneSystemTimerPeriod();
  DoneCounters();

  inherited Destroy();
end;


procedure TClock.SetFrameRateLimit(AFrameRateLimit: Integer);
begin
  FFrameRateLimit := AFrameRateLimit;
  FTicksPerFrame := FTicksPerSecond div FFrameRateLimit;
end;


function TClock.GetCounterFrequency(): Int64;
begin
  Result := 0;
  QueryPerformanceFrequency(Result);
end;


function TClock.GetCounterValue(): Int64;
begin
  Result := 0;
  QueryPerformanceCounter(Result);
end;


procedure TClock.InitSystemTimerPeriod();
var
  Periods: TTimeCaps;
begin
  if TimeGetDevCaps(@Periods, SizeOf(Periods)) = TIMERR_NOERROR then
  begin
    FTimerPeriod := Periods.wPeriodMin;
    TimeBeginPeriod(FTimerPeriod);
  end
  else
    FTimerPeriod := -1;
end;


procedure TClock.DoneSystemTimerPeriod();
begin
  if FTimerPeriod <> -1 then
    TimeEndPeriod(FTimerPeriod);
end;


procedure TClock.InitCounters();
begin
  FFrameRate := TClockFrameRate.Create(0);
  FFrameLoad := TClockFrameLoad.Create(0);
end;


procedure TClock.DoneCounters();
begin
  FFrameRate.Free();
  FFrameLoad.Free();
end;


procedure TClock.InitFrameRate();
begin
  FFrameRateSecond := SecondOf(Now());
  FFrameRateLimit := CLOCK_FRAMERATE_NTSC;
end;


procedure TClock.InitTicks();
begin
  FTicksPerSecond := GetCounterFrequency();
  FTicksPerFrame := FTicksPerSecond div FFrameRateLimit;
end;


procedure TClock.UpdateFrameRate();
var
  NewSecond: Integer;
begin
  NewSecond := SecondOf(Now());

  if NewSecond = FFrameRateSecond then
    FFrameRateTank += 1
  else
  begin
    FFrameRate.Current := FFrameRateTank;

    FFrameRateTank := 1;
    FFrameRateSecond := NewSecond;
  end;
end;


procedure TClock.UpdateFrameLoad();
begin
  if FFrameIndex mod (FFrameRateLimit div 4) <> 0 then
    FFrameLoadTank += (FFrameTicksEnd - FFrameTicksBegin) * 100 div FTicksPerFrame
  else
  begin
    FFrameLoad.Current := FFrameLoadTank div (FFrameRateLimit div 4);
    FFrameLoadTank := (FFrameTicksEnd - FFrameTicksBegin) * 100 div FTicksPerFrame;
  end;
end;


procedure TClock.Initialize();
begin
  // ustawić framerate według danych z "Settings"
end;


procedure TClock.UpdateFrameBegin();
begin
  FFrameTicksBegin := GetCounterValue();
  FFrameTicksNext := FFrameTicksBegin + FTicksPerFrame;
end;


procedure TClock.UpdateFrameEnd();
begin
  FFrameTicksEnd := GetCounterValue();
  FFrameIndex += 1;

  UpdateFrameRate();
  UpdateFrameLoad();
end;


procedure TClock.UpdateFrameAlign();
var
  SleepTime: Single;
begin
  SleepTime := 1000 / FFrameRateLimit * (1 - (FFrameTicksEnd - FFrameTicksBegin) / FTicksPerFrame) - 1;
  SleepTime -= Ord(Round(SleepTime) > SleepTime);
  SleepTime := Max(SleepTime, 0);

  Sleep(Round(SleepTime));

  while GetCounterValue() < FFrameTicksNext do
    Sleep(0);
end;


end.

