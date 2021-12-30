{
  Fairtris — a fair implementation of Classic Tetris®
  Copyleft (ɔ) furious programming 2021. All rights reversed.

  https://github.com/furious-programming/fairtris


  This is free and unencumbered software released into the public domain.

  Anyone is free to copy, modify, publish, use, compile, sell, or
  distribute this software, either in source code form or as a compiled
  binary, for any purpose, commercial or non-commercial, and by any means.

  For more information, see "LICENSE" or "license.txt" file, which should
  be included with this distribution. If not, check the repository.
}

unit Fairtris.Converter;

{$MODE OBJFPC}{$LONGSTRINGS ON}

interface

uses
  SDL2;


type
  TConverter = class(TObject)
  private
    procedure FramesToTimeComponents(AFramesCount: Integer; out AHours, AMinutes, ASeconds, AMilliseconds: Integer);
  public
    function ScanCodeToChar(AScanCode: TSDL_ScanCode): Char;
  public
    function TextToSeed(const AText: String): String;
    function TextToTimer(const AText: String): String;
  public
    function PiecesToString(APieces: Integer): String;
    function ScoreToString(AScore: Integer): String;
    function LinesToString(ALines: Integer): String;
    function LevelToString(ALevel: Integer): String;
    function BurnedToString(ABurned: Integer): String;
    function TetrisesToString(ATetrises: Integer): String;
    function GainToString(AGain: Integer): String;
    function FramesToTimeString(AFramesCount: Integer; AIsBestScore: Boolean = False): String;
  public
    procedure SeedEditorToStrings(const ASeedEditor: String; out ADigits, APlaceholder: String);
    procedure TimerEditorToStrings(const ATimerEditor: String; out ADigits, APlaceholder: String);
  public
    function StringToTimerSeconds(const ATimerEditor: String): Integer;
    function StringToTimerFrames(const ATimerEditor: String): Integer;
  end;


var
  Converter: TConverter;


implementation

uses
  SysUtils,
  Fairtris.Memory,
  Fairtris.Arrays,
  Fairtris.Constants;


procedure TConverter.FramesToTimeComponents(AFramesCount: Integer; out AHours, AMinutes, ASeconds, AMilliseconds: Integer);
var
  FramesCount, FramesPerHour, FramesPerMinute, FramesPerSecond: Integer;
begin
  FramesCount := AFramesCount;

  FramesPerSecond := CLOCK_FRAMERATE_LIMIT[Memory.GameModes.Region];
  FramesPerMinute := FramesPerSecond * 60;
  FramesPerHour   := FramesPerMinute * 60;

  AHours := FramesCount div FramesPerHour;
  FramesCount -= AHours * FramesPerHour;

  AMinutes := FramesCount div FramesPerMinute;
  FramesCount -= AMinutes * FramesPerMinute;

  ASeconds := FramesCount div FramesPerSecond;
  FramesCount -= ASeconds * FramesPerSecond;

  AMilliseconds := FramesCount * 1000 div FramesPerSecond;
end;


function TConverter.ScanCodeToChar(AScanCode: TSDL_ScanCode): Char;
begin
  Result := #0;

  if AScanCode = SDL_SCANCODE_0 then Exit('0');

  if AScanCode in [SDL_SCANCODE_1 .. SDL_SCANCODE_9] then Exit(Chr(AScanCode - SDL_SCANCODE_1 + Ord('1')));
  if AScanCode in [SDL_SCANCODE_A .. SDL_SCANCODE_F] then Exit(Chr(AScanCode - SDL_SCANCODE_A + Ord('A')));
end;


function TConverter.TextToSeed(const AText: String): String;
var
  Digit: Char;
begin
  Result := '';

  if AText.Length = SEED_LENGTH then
  begin
    Result := AText.ToUpper();

    for Digit in Result do
      if not (Digit in TEXT_HEX_DIGITS) then
        Exit('');
  end;
end;


function TConverter.TextToTimer(const AText: String): String;
var
  Index: Integer;
begin
  if AText.Length <> TIMER_LENGTH then Exit('');

  Result := AText.ToUpper();

  for Index := 1 to Result.Length do
    if TIMER_PLACEHOLDER[Index] = TIMER_SEPARATOR then
    begin
      if Result[Index] in TEXT_DATE_SEPARATORS then
        Result[Index] := TIMER_SEPARATOR
      else
        Exit('');
    end
    else
    begin
      if not (Result[Index] in TEXT_DIGITS)      then Exit('');
      if Result[Index] > TIMER_MAX_DIGITS[Index] then Exit('');
    end;
end;


function TConverter.PiecesToString(APieces: Integer): String;
begin
  Result := '%.3d'.Format([APieces]);
end;


function TConverter.ScoreToString(AScore: Integer): String;
var
  Prefix: Integer;
begin
  if Memory.Options.Theme = THEME_MODERN then
    Result := '%.7d'.Format([AScore])
  else
  begin
    Result := '%.6d'.Format([AScore]);

    if Result.Length > 6 then
    begin
      Prefix := Result.Substring(0, 2).ToInteger();
      Result := Result.Remove(0, 2);
      Result := Result.Insert(0, Chr(Prefix + Ord('A') - 10));
    end;
  end;
end;


function TConverter.LinesToString(ALines: Integer): String;
begin
  if Memory.Options.Theme = THEME_MODERN then
    Result := ALines.ToString()
  else
    Result := '%.3d'.Format([ALines]);
end;


function TConverter.LevelToString(ALevel: Integer): String;
begin
  if Memory.Options.Theme = THEME_MODERN then
    Result := ALevel.ToString()
  else
    Result := '%.2d'.Format([ALevel]);
end;


function TConverter.BurnedToString(ABurned: Integer): String;
begin
  Result := ABurned.ToString();
end;


function TConverter.TetrisesToString(ATetrises: Integer): String;
begin
  Result := ATetrises.ToString() + '%';
end;


function TConverter.GainToString(AGain: Integer): String;
begin
  Result := AGain.ToString();
end;


function TConverter.FramesToTimeString(AFramesCount: Integer; AIsBestScore: Boolean): String;
var
  Hours, Minutes, Seconds, Milliseconds: Integer;
var
  TimeFormatDecimal: String = TIME_FORMAT_DECIMAL_MENU;
begin
  FramesToTimeComponents(AFramesCount, Hours, Minutes, Seconds, Milliseconds);

  if not AIsBestScore then
    if Memory.Options.Theme = THEME_MODERN then
    begin
      Milliseconds := Trunc(Milliseconds / 10);
      TimeFormatDecimal := TIME_FORMAT_DECIMAL_MODERN;
    end
    else
    begin
      Milliseconds := Trunc(Milliseconds / 100);
      TimeFormatDecimal := TIME_FORMAT_DECIMAL_CLASSIC;
    end;

  Result := (TIME_FORMAT_MAJOR + TimeFormatDecimal).Format([Minutes, Seconds, Milliseconds]);
end;


procedure TConverter.SeedEditorToStrings(const ASeedEditor: String; out ADigits, APlaceholder: String);
begin
  ADigits := ASeedEditor;
  APlaceholder := SEED_PLACEHOLDER.Substring(ADigits.Length);
end;


procedure TConverter.TimerEditorToStrings(const ATimerEditor: String; out ADigits, APlaceholder: String);
begin
  ADigits := ATimerEditor;
  APlaceholder := TIMER_PLACEHOLDER.Substring(ADigits.Length);
end;


function TConverter.StringToTimerSeconds(const ATimerEditor: String): Integer;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours   := ATimerEditor.Substring(0, 1).ToInteger();
  Minutes := ATimerEditor.Substring(2, 2).ToInteger();
  Seconds := ATimerEditor.Substring(5, 2).ToInteger();

  Result := Hours * 3600 + Minutes * 60 + Seconds;
end;


function TConverter.StringToTimerFrames(const ATimerEditor: String): Integer;
begin
  Result := StringToTimerSeconds(ATimerEditor) * CLOCK_FRAMERATE_LIMIT[Memory.GameModes.Region];
end;


end.

