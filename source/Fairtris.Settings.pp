unit Fairtris.Settings;

{$MODE OBJFPC}{$LONGSTRINGS ON}

interface

uses
  IniFiles,
  Fairtris.Constants;


type
  TCustomSettings = class(TObject)
  protected
    function CorrectRange(AValue, AFirst, ALast, ADefault: Integer): Integer;
  end;


type
  TVideoSettings = class(TCustomSettings)
  private
    FEnabled: Boolean;
    FWidth: Integer;
    FHeight: Integer;
  private
    procedure Collect();
  public
    procedure Load(AFile: TIniFile; const ASection: String);
    procedure Save(AFile: TIniFile; const ASection: String);
  public
    property Enabled: Boolean read FEnabled;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
  end;


type
  TGeneralSettings = class(TCustomSettings)
  private
    FDeflored: Boolean;
  private
    FMonitor: Integer;
    FLeft: Integer;
    FTop: Integer;
  private
    FInput: Integer;
    FSize: Integer;
    FTheme: Integer;
    FSounds: Integer;
    FScroll: Integer;
  private
    FRegion: Integer;
    FRNG: Integer;
    FLevel: Integer;
  private
    function CorrectMonitor(AValue: Integer): Integer;
    function CorrectLeft(AValue: Integer): Integer;
    function CorrectTop(AValue: Integer): Integer;
    function CorrectLevel(AValue: Integer): Integer;
  private
    function DetermineMonitor(): Integer;
  private
    procedure Correct();
    procedure Collect();
  public
    procedure Load(AFile: TIniFile; const ASection: String);
    procedure Save(AFile: TIniFile; const ASection: String);
  public
    property Deflored: Boolean read FDeflored;
  public
    property Monitor: Integer read FMonitor;
    property Left: Integer read FLeft;
    property Top: Integer read FTop;
  public
    property Input: Integer read FInput;
    property Size: Integer read FSize;
    property Theme: Integer read FTheme;
    property Sounds: Integer read FSounds;
    property Scroll: Integer read FScroll;
  public
    property Region: Integer read FRegion;
    property RNG: Integer read FRNG;
    property Level: Integer read FLevel;
  end;


type
  TMappingSettings = class(TCustomSettings)
  private
    FDeviceID: Integer;
  private
    procedure Collect();
  public
    constructor Create(ADeviceID: Integer);
  public
    procedure Load(AFile: TIniFile; const ASection: String); virtual; abstract;
    procedure Save(AFile: TIniFile; const ASection: String);
  public
    ScanCodes: array [DEVICE_FIRST .. DEVICE_LAST] of UInt8;
  end;


type
  TKeyboardSettings = class(TMappingSettings)
  public
    procedure Load(AFile: TIniFile; const ASection: String); override;
  end;


type
  TControllerSettings = class(TMappingSettings)
  public
    procedure Load(AFile: TIniFile; const ASection: String); override;
  end;


type
  TSettings = class(TObject)
  private
    FSettingsFile: TMemIniFile;
  private
    FGeneral: TGeneralSettings;
    FVideo: TVideoSettings;
    FKeyboard: TKeyboardSettings;
    FController: TControllerSettings;
  public
    constructor Create();
    destructor Destroy(); override;
  public
    procedure Load();
    procedure Save();
  public
    property Video: TVideoSettings read FVideo;
    property General: TGeneralSettings read FGeneral;
    property Keyboard: TKeyboardSettings read FKeyboard;
    property Controller: TControllerSettings read FController;
  end;


var
  Settings: TSettings;


implementation

uses
  SDL2,
  Fairtris.Window,
  Fairtris.Input,
  Fairtris.Memory,
  Fairtris.Placement,
  Fairtris.Arrays;


function TCustomSettings.CorrectRange(AValue, AFirst, ALast, ADefault: Integer): Integer;
begin
  if (AValue >= AFirst) and (AValue <= ALast) then
    Result := AValue
  else
    Result := ADefault;
end;


procedure TVideoSettings.Collect();
begin
  FEnabled := Placement.VideoEnabled;

  FWidth := Placement.VideoWidth;
  FHeight := Placement.VideoHeight;
end;


procedure TVideoSettings.Load(AFile: TIniFile; const ASection: String);
begin
  FEnabled := AFile.ReadBool(ASection, SETTINGS_KEY_VIDEO_ENABLED, SETTINGS_VALUE_VIDEO_ENABLED);

  FWidth  := AFile.ReadInteger(ASection, SETTINGS_KEY_VIDEO_WIDTH,  SETTINGS_VALUE_VIDEO_WIDTH);
  FHeight := AFile.ReadInteger(ASection, SETTINGS_KEY_VIDEO_HEIGHT, SETTINGS_VALUE_VIDEO_HEIGHT);
end;


procedure TVideoSettings.Save(AFile: TIniFile; const ASection: String);
begin
  AFile.WriteBool(ASection, SETTINGS_KEY_VIDEO_ENABLED, FEnabled);

  AFile.WriteInteger(ASection, SETTINGS_KEY_VIDEO_WIDTH,  FWidth);
  AFile.WriteInteger(ASection, SETTINGS_KEY_VIDEO_HEIGHT, FHeight);
end;


function TGeneralSettings.CorrectMonitor(AValue: Integer): Integer;
begin
  Result := AValue;

  if (Result < 0) or (Result > SDL_GetNumVideoDisplays() - 1) then
    Result := MONITOR_DEFAULT;
end;


function TGeneralSettings.CorrectLeft(AValue: Integer): Integer;
var
  MonitorBounds: TSDL_Rect;
begin
  Result := AValue;

  if SDL_GetDisplayBounds(FMonitor, @MonitorBounds) = 0 then
  begin
    if Result < MonitorBounds.X then Exit(0);
    if Result > MonitorBounds.X + MonitorBounds.W - BUFFER_WIDTH then Exit(0);
  end
  else
    Result := 0;
end;


function TGeneralSettings.CorrectTop(AValue: Integer): Integer;
var
  MonitorBounds: TSDL_Rect;
begin
  Result := AValue;

  if SDL_GetDisplayBounds(FMonitor, @MonitorBounds) = 0 then
  begin
    if Result < MonitorBounds.Y then Exit(0);
    if Result > MonitorBounds.Y + MonitorBounds.H - BUFFER_HEIGHT then Exit(0);
  end
  else
    Result := 0;
end;


function TGeneralSettings.CorrectLevel(AValue: Integer): Integer;
begin
  Result := AValue;

  case Result of
    REGION_NTSC .. REGION_JPN_EXTENDED, REGION_EUR .. REGION_EUR_EXTENDED:
      if (Result < LEVEL_FIRST_NTSC) or (Result > LEVEL_LAST_NTSC) then
        Result := LEVEL_DEFAULT;
    REGION_PAL .. REGION_PAL_EXTENDED:
      if (Result < LEVEL_FIRST_PAL) or (Result > LEVEL_LAST_PAL) then
        Result := LEVEL_DEFAULT;
  end;
end;


function TGeneralSettings.DetermineMonitor(): Integer;
begin
  Result := SDL_GetWindowDisplayIndex(Window.Window);
end;


procedure TGeneralSettings.Correct();
begin
  FMonitor := CorrectMonitor(FMonitor);
  FLeft := CorrectLeft(FLeft);
  FTop := CorrectTop(FTop);

  FInput  := CorrectRange(FInput,  INPUT_FIRST,  INPUT_LAST,  INPUT_DEFAULT);
  FSize   := CorrectRange(FSize,   SIZE_FIRST,   SIZE_LAST,   SIZE_DEFAULT);
  FTheme  := CorrectRange(FTheme,  THEME_FIRST,  THEME_LAST,  THEME_DEFAULT);
  FSounds := CorrectRange(FSounds, SOUNDS_FIRST, SOUNDS_LAST, SOUNDS_DEFAULT);
  FScroll := CorrectRange(FScroll, SCROLL_FIRST, SCROLL_LAST, SCROLL_DEFAULT);

  FRegion := CorrectRange(FRegion, REGION_FIRST, REGION_LAST, REGION_DEFAULT);
  FRNG    := CorrectRange(FRNG,    RNG_FIRST,    RNG_LAST,    RNG_DEFAULT);
  FLevel  := CorrectLevel(FLevel);
end;


procedure TGeneralSettings.Collect();
begin
  FDeflored := Placement.Deflored;

  FMonitor := DetermineMonitor();
  FSize := Placement.WindowSize;
  FLeft := Placement.WindowBounds.X;
  FTop := Placement.WindowBounds.Y;

  FInput := Memory.Options.Input;
  FTheme := Memory.Options.Theme;
  FSounds := Memory.Options.Sounds;
  FScroll := Memory.Options.Scroll;

  FRegion := Memory.Play.Region;
  FRNG := Memory.Play.RNG;
  FLevel := Memory.Play.Level;
end;


procedure TGeneralSettings.Load(AFile: TIniFile; const ASection: String);
begin
  FDeflored := AFile.ReadBool(ASection, SETTINGS_KEY_GENERAL_DEFLORED, SETTINGS_VALUE_GENERAL_DEFLORED);

  FMonitor := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_MONITOR, SETTINGS_VALUE_GENERAL_MONITOR);
  FLeft    := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_LEFT,    SETTINGS_VALUE_GENERAL_LEFT);
  FTop     := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_TOP,     SETTINGS_VALUE_GENERAL_TOP);

  FInput  := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_INPUT,  SETTINGS_VALUE_GENERAL_INPUT);
  FSize   := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_SIZE,   SETTINGS_VALUE_GENERAL_SIZE);
  FTheme  := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_THEME,  SETTINGS_VALUE_GENERAL_THEME);
  FSounds := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_SOUNDS, SETTINGS_VALUE_GENERAL_SOUNDS);
  FScroll := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_SCROLL, SETTINGS_VALUE_GENERAL_SCROLL);

  FRegion := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_REGION, SETTINGS_VALUE_GENERAL_REGION);
  FRNG    := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_RNG,    SETTINGS_VALUE_GENERAL_RNG);
  FLevel  := AFile.ReadInteger(ASection, SETTINGS_KEY_GENERAL_LEVEL,  SETTINGS_VALUE_GENERAL_LEVEL);

  Correct();
end;


procedure TGeneralSettings.Save(AFile: TIniFile; const ASection: String);
begin
  AFile.WriteBool(ASection, SETTINGS_KEY_GENERAL_DEFLORED, FDeflored);

  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_MONITOR, FMonitor);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_LEFT,    FLeft);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_TOP,     FTop);

  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_INPUT,  FInput);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_SIZE,   FSize);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_THEME,  FTheme);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_SOUNDS, FSounds);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_SCROLL, FScroll);

  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_REGION, FRegion);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_RNG,    FRNG);
  AFile.WriteInteger(ASection, SETTINGS_KEY_GENERAL_LEVEL,  FLevel);
end;


constructor TMappingSettings.Create(ADeviceID: Integer);
begin
  FDeviceID := ADeviceID;
end;


procedure TMappingSettings.Collect();
var
  Index: Integer;
begin
  for Index := DEVICE_FIRST to DEVICE_LAST do
    ScanCodes[Index] := Input[FDeviceID].ScanCode[Index];
end;


procedure TMappingSettings.Save(AFile: TIniFile; const ASection: String);
var
  Index: Integer;
begin
  for Index := DEVICE_FIRST to DEVICE_LAST do
    AFile.WriteInteger(ASection, SETTINGS_KEY_MAPPING[Index], ScanCodes[Index]);
end;


procedure TKeyboardSettings.Load(AFile: TIniFile; const ASection: String);
var
  Index, ScanCode: Integer;
begin
  for Index := DEVICE_FIRST to DEVICE_LAST do
  begin
    ScanCode := AFile.ReadInteger(ASection, SETTINGS_KEY_MAPPING[Index], KEYBOARD_SCANCODE_KEY_NOT_MAPPED);
    ScanCodes[Index] := CorrectRange(
      ScanCode,
      KEYBOARD_SCANCODE_KEY_FIRST,
      KEYBOARD_SCANCODE_KEY_LAST,
      KEYBOARD_SCANCODE_KEY_NOT_MAPPED
    );
  end;
end;


procedure TControllerSettings.Load(AFile: TIniFile; const ASection: String);
var
  Index, ScanCode: Integer;
begin
  for Index := DEVICE_FIRST to DEVICE_LAST do
  begin
    ScanCode := AFile.ReadInteger(ASection, SETTINGS_KEY_MAPPING[Index], CONTROLLER_SCANCODE_BUTTON_NOT_MAPPED);
    ScanCodes[Index] := CorrectRange(
      ScanCode,
      CONTROLLER_SCANCODE_BUTTON_FIRST,
      CONTROLLER_SCANCODE_BUTTON_LAST,
      CONTROLLER_SCANCODE_BUTTON_NOT_MAPPED
    );
  end;
end;


constructor TSettings.Create();
begin
  FSettingsFile := TMemIniFile.Create(SETTINGS_FILENAME);

  FVideo := TVideoSettings.Create();
  FGeneral := TGeneralSettings.Create();
  FKeyboard := TKeyboardSettings.Create(INPUT_KEYBOARD);
  FController := TControllerSettings.Create(INPUT_CONTROLLER);
end;


destructor TSettings.Destroy();
begin
  FSettingsFile.Free();

  FVideo.Free();
  FGeneral.Free();
  FKeyboard.Free();
  FController.Free();

  inherited Destroy();
end;


procedure TSettings.Load();
begin
  FVideo.Load(FSettingsFile, SETTINGS_SECTION_VIDEO);
  FGeneral.Load(FSettingsFile, SETTINGS_SECTION_GENERAL);
  FKeyboard.Load(FSettingsFile, SETTINGS_SECTION_KEYBOARD);
  FController.Load(FSettingsFile, SETTINGS_SECTION_CONTROLLER);
end;


procedure TSettings.Save();
begin
  FVideo.Collect();
  FGeneral.Collect();
  FKeyboard.Collect();
  FController.Collect();

  FVideo.Save(FSettingsFile, SETTINGS_SECTION_VIDEO);
  FGeneral.Save(FSettingsFile, SETTINGS_SECTION_GENERAL);
  FKeyboard.Save(FSettingsFile, SETTINGS_SECTION_KEYBOARD);
  FController.Save(FSettingsFile, SETTINGS_SECTION_CONTROLLER);
end;


end.

