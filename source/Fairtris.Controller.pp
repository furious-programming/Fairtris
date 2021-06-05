unit Fairtris.Controller;

{$MODE OBJFPC}{$LONGSTRINGS ON}

interface

uses
  MMSystem,
  Classes,
  Fairtris.Interfaces,
  Fairtris.Classes,
  Fairtris.Constants;


type
  TDeviceUpdater = class(TThread)
  private
    FDeviceStatus: PJOYINFOEX;
    FDeviceConnected: PBoolean;
  private
    FLocalStatus: JOYINFOEX;
    FLocalConnected: Boolean;
  private
    procedure UpdateDevice();
  public
    constructor Create(AStatus: PJOYINFOEX; AConnected: PBoolean);
  public
    procedure Execute(); override;
  end;


type
  TDevice = class(TObject)
  private type
    TArrows = array [0 .. 3] of TSwitch;
    TButtons = array [0 .. 31] of TSwitch;
  private
    FUpdater: TDeviceUpdater;
  private
    FStatus: JOYINFOEX;
    FConnected: Boolean;
  private
    FArrows: TArrows;
    FButtons: TButtons;
  private
    procedure InitArrows();
    procedure InitButtons();
    procedure InitUpdater();
  private
    procedure DoneUpdater();
    procedure DoneArrows();
    procedure DoneButtons();
  private
    procedure UpdateArrows();
    procedure UpdateButtons();
  private
    function GetArrow(AIndex: Integer): TSwitch;
    function GetButton(AIndex: Integer): TSwitch;
  public
    constructor Create();
    destructor Destroy(); override;
  public
    procedure Reset();
    procedure Update();
  public
    procedure Validate();
    procedure Invalidate();
  public
    property Arrow[AIndex: Integer]: TSwitch read GetArrow;
    property Button[AIndex: Integer]: TSwitch read GetButton;
  public
    property Connected: Boolean read FConnected;
  end;


type
  TController = class(TInterfacedObject, IControllable)
  private type
    TScanCodes = array [0 .. 7] of UInt8;
  private
    FDevice: TDevice;
    FScanCodes: TScanCodes;
  private
    procedure InitDevice();
    procedure InitScanCodes();
  private
    procedure DoneDevice();
  private
    function GetSwitch(AIndex: Integer): TSwitch;
    function GetScanCode(AIndex: Integer): UInt8;
    function GetConnected(): Boolean;
  public
    constructor Create();
    destructor Destroy(); override;
  public
    procedure Initialize();
  public
    procedure Reset();
    procedure Update();
    procedure Restore();
  public
    procedure Validate();
    procedure Invalidate();
  public
    property Device: TDevice read FDevice;
  public
    property Connected: Boolean read GetConnected;
    property ScanCode[AIndex: Integer]: UInt8 read GetScanCode;
  public
    property Up: TSwitch index CONTROLLER_BUTTON_UP read GetSwitch;
    property Down: TSwitch index CONTROLLER_BUTTON_DOWN read GetSwitch;
    property Left: TSwitch index CONTROLLER_BUTTON_LEFT read GetSwitch;
    property Right: TSwitch index CONTROLLER_BUTTON_RIGHT read GetSwitch;
    property Select: TSwitch index CONTROLLER_BUTTON_SELECT read GetSwitch;
    property Start: TSwitch index CONTROLLER_BUTTON_START read GetSwitch;
    property B: TSwitch index CONTROLLER_BUTTON_B read GetSwitch;
    property A: TSwitch index CONTROLLER_BUTTON_A read GetSwitch;
  end;


implementation


constructor TDeviceUpdater.Create(AStatus: PJOYINFOEX; AConnected: PBoolean);
begin
  inherited Create(False);

  FDeviceStatus := AStatus;
  FDeviceConnected := AConnected;
end;


procedure TDeviceUpdater.UpdateDevice();
begin
  FDeviceStatus^ := FLocalStatus;
  FDeviceConnected^ := FLocalConnected;
end;


procedure TDeviceUpdater.Execute();
begin
  while not Terminated do
  begin
    FLocalStatus := Default(JOYINFOEX);
    FLocalStatus.dwSize := SizeOf(JOYINFOEX);
    FLocalStatus.dwFlags := JOY_RETURNX or JOY_RETURNY or JOY_RETURNBUTTONS;

    FLocalConnected := joyGetPosEx(JOYSTICKID1, @FLocalStatus) = JOYERR_NOERROR;

    Synchronize(@UpdateDevice);
    Sleep(10);
  end;
end;


constructor TDevice.Create();
begin
  InitArrows();
  InitButtons();
  InitUpdater();
end;


destructor TDevice.Destroy();
begin
  DoneUpdater();
  DoneArrows();
  DoneButtons();

  inherited Destroy();
end;


procedure TDevice.InitArrows();
var
  Index: Integer;
begin
  for Index := Low(FArrows) to High(FArrows) do
    FArrows[Index] := TSwitch.Create(False);
end;


procedure TDevice.InitButtons();
var
  Index: Integer;
begin
  for Index := Low(FButtons) to High(FButtons) do
    FButtons[Index] := TSwitch.Create(False);
end;


procedure TDevice.InitUpdater();
begin
  FUpdater := TDeviceUpdater.Create(@FStatus, @FConnected);
  FUpdater.FreeOnTerminate := True;
end;


procedure TDevice.DoneUpdater();
begin
  FUpdater.Terminate();
  FUpdater.WaitFor();
end;


procedure TDevice.DoneArrows();
var
  Index: Integer;
begin
  for Index := Low(FArrows) to High(FArrows) do
    FArrows[Index].Free();
end;


procedure TDevice.DoneButtons();
var
  Index: Integer;
begin
  for Index := Low(FButtons) to High(FButtons) do
    FButtons[Index].Free();
end;


procedure TDevice.UpdateArrows();
begin
  FArrows[CONTROLLER_BUTTON_UP].Pressed    := FStatus.wYpos = $0000;
  FArrows[CONTROLLER_BUTTON_DOWN].Pressed  := FStatus.wYpos = $FFFF;
  FArrows[CONTROLLER_BUTTON_LEFT].Pressed  := FStatus.wXpos = $0000;
  FArrows[CONTROLLER_BUTTON_RIGHT].Pressed := FStatus.wXpos = $FFFF;
end;


procedure TDevice.UpdateButtons();
var
  Index: Integer;
  Mask: Integer = JOY_BUTTON1;
begin
  for Index := Low(FButtons) to High(FButtons) do
  begin
    FButtons[Index].Pressed := FStatus.wButtons and Mask <> 0;
    Mask := Mask shl 1;
  end;
end;


function TDevice.GetArrow(AIndex: Integer): TSwitch;
begin
  Result := FArrows[AIndex];
end;


function TDevice.GetButton(AIndex: Integer): TSwitch;
begin
  Result := FButtons[AIndex];
end;


procedure TDevice.Reset();
var
  Index: Integer;
begin
  FStatus := Default(JOYINFOEX);

  for Index := Low(FArrows) to High(FArrows) do
    FArrows[Index].Reset();

  for Index := Low(FButtons) to High(FButtons) do
    FButtons[Index].Reset();
end;


procedure TDevice.Update();
begin
  if FConnected then
  begin
    UpdateArrows();
    UpdateButtons();
  end
  else
    Reset();
end;


procedure TDevice.Validate();
var
  Index: Integer;
begin
  for Index := Low(FArrows) to High(FArrows) do
    FArrows[Index].Validate();

  for Index := Low(FButtons) to High(FButtons) do
    FButtons[Index].Validate();
end;


procedure TDevice.Invalidate();
var
  Index: Integer;
begin
  for Index := Low(FArrows) to High(FArrows) do
    FArrows[Index].Invalidate();

  for Index := Low(FButtons) to High(FButtons) do
    FButtons[Index].Invalidate();
end;


constructor TController.Create();
begin
  InitDevice();
  InitScanCodes();
end;


destructor TController.Destroy();
begin
  DoneDevice();
  inherited Destroy();
end;


procedure TController.InitDevice();
begin
  FDevice := TDevice.Create();
end;


procedure TController.InitScanCodes();
begin
  Restore();
end;


procedure TController.DoneDevice();
begin
  FDevice.Free();
end;


function TController.GetSwitch(AIndex: Integer): TSwitch;
begin
  if AIndex in [CONTROLLER_BUTTON_UP .. CONTROLLER_BUTTON_RIGHT] then
    Result := FDevice.Arrow[FScanCodes[AIndex]]
  else
    Result := FDevice.Button[FScanCodes[AIndex]];
end;


function TController.GetScanCode(AIndex: Integer): UInt8;
begin
  Result := FScanCodes[AIndex];
end;


function TController.GetConnected(): Boolean;
begin
  Result := FDevice.Connected;
end;


procedure TController.Initialize();
begin
  // załadować kody przycisków z "Settings" i wpisać je do FScanCodes
end;


procedure TController.Reset();
begin
  FDevice.Reset();
end;


procedure TController.Update();
begin
  FDevice.Update();
end;


procedure TController.Restore();
begin
  FScanCodes[CONTROLLER_BUTTON_UP]     := CONTROLLER_BUTTON_UP;
  FScanCodes[CONTROLLER_BUTTON_DOWN]   := CONTROLLER_BUTTON_DOWN;
  FScanCodes[CONTROLLER_BUTTON_LEFT]   := CONTROLLER_BUTTON_LEFT;
  FScanCodes[CONTROLLER_BUTTON_RIGHT]  := CONTROLLER_BUTTON_RIGHT;

  FScanCodes[CONTROLLER_BUTTON_SELECT] := 0;
  FScanCodes[CONTROLLER_BUTTON_START]  := 1;
  FScanCodes[CONTROLLER_BUTTON_B]      := 2;
  FScanCodes[CONTROLLER_BUTTON_A]      := 3;
end;


procedure TController.Validate();
begin
  FDevice.Validate();
end;


procedure TController.Invalidate();
begin
  FDevice.Invalidate();
end;


end.

