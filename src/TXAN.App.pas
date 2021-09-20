unit TXAN.App;

{$IFDEF FPC}
  {$mode delphi}
{$ENDIF}


interface

uses 
  SysUtils,
  Classes,

  JPL.Strings, JPL.TStr, JPL.Conversion, JPL.Console, JPL.ConsoleApp,
  JPL.CmdLineParser, JPL.FileSearcher, JPL.TimeLogger, JPL.Files,

  TXAN.Types;

type


  TApp = class(TJPConsoleApp)
  private
    AppParams: TAppParams;
    FList: TStringList;
    FStats: TTotalStats;
    FGithubUrl: string;
  public
    procedure Init;
    procedure Run;
    procedure Done;

    procedure RegisterOptions;
    procedure ProcessOptions;

    procedure PerfromTasks;
    procedure ProcessFileList;
    procedure ProcessFile(const FileName: string; var fs: TFileStats);
    procedure DisplaySummary;

    procedure DisplayHelpAndExit(const ExCode: integer);
    procedure DisplayShortUsageAndTerminate(const Msg: string; const ExCode: integer);
    procedure DisplayShortUsageAndExit(const Msg: string; const ExCode: integer);
    procedure DisplayBannerAndExit(const ExCode: integer);
    procedure DisplayMessageAndExit(const Msg: string; const ExCode: integer);
  end;



implementation



{$region '                    Init                              '}

procedure TApp.Init;
begin
  //----------------------------------------------------------------------------

  AppName := 'TxtAn';
  MajorVersion := 1;
  MinorVersion := 0;
  Date := EncodeDate(2021, 9, 20);
  FullNameFormat := '%AppName% %MajorVersion%.%MinorVersion% [%OSShort% %Bits%-bit] (%AppDate%)';
  Description := 'The program counts the lines of text in the given text files.';
  LicenseName := 'Freeware, OpenSource';
  Author := 'Jacek Pazera';
  HomePage := 'https://www.pazera-software.com/products/text-analyzer/';
  FGithubUrl := 'https://github.com/jackdp/TxtAn';
  //HelpPage := HomePage;



  //-----------------------------------------------------------------------------

  TryHelpStr := ENDL + 'Try "' + ExeShortName + ' --help for more info.';

  ShortUsageStr :=
    ENDL +
    'Usage: ' + ExeShortName +
    ' FILES [-ifsl] [-idsl] [-r=[X]] [-s] [-h] [-V] [--github]' + ENDL +
    ENDL +
    'Mandatory arguments to long options are mandatory for short options too.' + ENDL +
    'Options are <color=cyan>case-sensitive</color>. Options in square brackets are optional.' + ENDL +
    'All parameters that do not start with the "-" or "/" sign are treated as <color=yellow>file names/masks</color>.' + ENDL +
    'Options and input files can be placed in any order, but -- (double dash)' + ENDL +
    'indicates the end of parsing options and all subsequent parameters are treated as file names/masks.' +
    ENDL + ENDL +
    'FILES - any combination of file names/masks.';

  //------------------------------------------------------------------------------

  SetLength(AppParams.FileMasks, 0);
  AppParams.IgnoreFileSymLinks := True;
  AppParams.IgnoreDirSymLinks := True;
  AppParams.RecursionDepth := 50;
  AppParams.Silent := False;
  AppParams.ShowSummary := True;

  FStats.Clear;
  FList := TStringList.Create;

end;
{$endregion Init}

procedure TApp.Done;
begin
  FList.Free;
  SetLength(AppParams.FileMasks, 0);
end;


{$region '                    Run                               '}
procedure TApp.Run;
begin
  inherited;

  RegisterOptions;
  Cmd.Parse;
  ProcessOptions;
  if Terminated then Exit;

  PerfromTasks; // <----- the main procedure
end;


{$endregion Run}


{$region '                    RegisterOptions                   '}
procedure TApp.RegisterOptions;
const
  MAX_LINE_LEN = 120;
var
  Category: string;
begin

  Cmd.CommandLineParsingMode := cpmCustom;
  Cmd.UsageFormat := cufWget;
  Cmd.AcceptAllNonOptions := True; // non options = file masks


  // ------------ Registering command-line options -----------------

  Category := 'inout';

  Cmd.RegisterOption('ifsl', 'ignore-file-symlinks', cvtNone, False, False, 'Ignore symbolic links to files.', '', Category);
  Cmd.RegisterOption('idsl', 'ignore-dir-symlinks', cvtNone, False, False, 'Ignore symbolic links to directories.', '', Category);
  Cmd.RegisterOption(
    'r', 'recurse-depth', cvtOptional, False, False,
    'Recurse subdirectories. X - recursion depth (def. X = ' + itos(AppParams.RecursionDepth) + ')', 'X', Category
  );
  Cmd.RegisterOption('s', 'silent', cvtNone, False, False, 'Only display a summary (no details).', '', Category);



  Category := 'info';
  Cmd.RegisterOption('h', 'help', cvtNone, False, False, 'Show this help.', '', Category);
  Cmd.RegisterShortOption('?', cvtNone, False, True, '', '', '');
  Cmd.RegisterOption('V', 'version', cvtNone, False, False, 'Show application version.', '', Category);
  Cmd.RegisterLongOption('github', cvtNone, False, False, 'Opens source code repository on the GitHub.', '', Category);

  UsageStr :=
    ENDL +
    'Input/output:' + ENDL + Cmd.OptionsUsageStr('  ', 'inout', MAX_LINE_LEN, '  ', 30) + ENDL + ENDL +
    'Info:' + ENDL + Cmd.OptionsUsageStr('  ', 'info', MAX_LINE_LEN, '  ', 30);

end;
{$endregion RegisterOptions}


{$region '                    ProcessOptions                    '}
procedure TApp.ProcessOptions;
var
  i: integer;
  s: string;
  xb: Byte;
begin

  // ---------------------------- Invalid options -----------------------------------
  if Cmd.ErrorCount > 0 then
  begin
    DisplayShortUsageAndExit(Cmd.ErrorsStr, CON_EXIT_CODE_SYNTAX_ERROR);
    Exit;
  end;


  //------------------------------------ Help ---------------------------------------
  if (ParamCount = 0) or (Cmd.IsLongOptionExists('help')) or (Cmd.IsOptionExists('?')) then
  begin
    DisplayHelpAndExit(CON_EXIT_CODE_OK);
    Exit;
  end;


  //---------------------------------- Home -----------------------------------------
  //if Cmd.IsLongOptionExists('home') then GoToHomePage; // and continue

  if Cmd.IsLongOptionExists('github') then
  begin
    GoToUrl(FGithubUrl);
    Exit;
  end;


  //------------------------------- Version ------------------------------------------
  if Cmd.IsOptionExists('version') then
  begin
    DisplayBannerAndExit(CON_EXIT_CODE_OK);
    Exit;
  end;


  // --------------- Silent -----------------
  AppParams.Silent := Cmd.IsOptionExists('s');


  // -------------- Recursion -----------------
  if Cmd.IsOptionExists('r') then
  begin
    s := Cmd.GetOptionValue('r', '');
    if s <> '' then
    begin
      if not TryStrToByte(s, xb) then
      begin
        DisplayError('The recursion depth should be an integer between 0 and 255.');
        Exit;
      end;
      AppParams.RecursionDepth := xb;
    end;
  end;

  // --------------------- Errors -----------------------
  if Cmd.ErrorCount > 0 then
  begin
    DisplayShortUsageAndTerminate(Cmd.ErrorsStr, CON_EXIT_CODE_SYNTAX_ERROR);
    Exit;
  end;

  // ---------------------- file masks -------------------------
  if Cmd.UnknownParamCount > 0 then
  begin
    SetLength(AppParams.FileMasks, Cmd.UnknownParamCount);
    for i := 0 to Cmd.UnknownParamCount - 1 do
      AppParams.FileMasks[i] := Cmd.UnknownParams[i].ParamStr;
  end;

  if Length(AppParams.FileMasks) = 0 then
  begin
    DisplayError('At least one file mask was expected!');
    Terminate;
  end;
end;


{$endregion ProcessOptions}




{$region '                    Main task                     '}

procedure TApp.PerfromTasks;
var
  i: integer;
  fs: TJPFileSearcher;
  Mask: string;
begin
  if Terminated then Exit;
  if Length(AppParams.FileMasks) = 0 then Exit;
  TTimeLogger.StartLog;

  fs := TJPFileSearcher.Create;
  try

    fs.FileInfoMode := fimOnlyFileNames;
    fs.AcceptDirectorySymLinks := not AppParams.IgnoreDirSymLinks;
    fs.AcceptFileSymLinks := not AppParams.IgnoreFileSymLinks;

    for i := 0 to High(AppParams.FileMasks) do
    begin
      Mask := AppParams.FileMasks[i];
      fs.AddInput(Mask, AppParams.RecursionDepth);
    end;

    fs.Search;

    if fs.OutputCount = 0 then
    begin
      DisplayHint('No files found');
      Exit;
    end;

    fs.GetFileList(FList);
    ProcessFileList;

    FList.Clear;

  finally
    fs.Free;
  end;

  TTimeLogger.EndLog;
  AppParams.ElapsedTimeStr := TTimeLogger.ElapsedTimeStr;

  if AppParams.ShowSummary then DisplaySummary;
end;

procedure TApp.ProcessFileList;
var
  i, xFileNo: integer;
  fName, sCount: string;
  fs: TFileStats;
begin
  if FList.Count = 0 then Exit;

  sCount := IntToStrEx(FList.Count);
  if not AppParams.Silent then Writeln('Files: ' + sCount);
  xFileNo := 0;

  for i := 0 to FList.Count - 1 do
  begin
    fName := FList[i];
    if not FileExists(fName) then Continue;

    Inc(xFileNo);
    fs.Clear;

    if not AppParams.Silent then TConsole.WriteTaggedTextLine(
      'Processing file ' + IntToStrEx(i + 1) + ' / ' + sCount + ': <color=yellow>' + fName + '</color>'
    );

    ProcessFile(fName, fs);
    FStats.AddFileStats(fs);

    if not AppParams.Silent then
    begin
      Writeln('File size: ' + GetFileSizeString(fs.FileSize));
      Writeln('Lines: ' + IntToStrEx(fs.Lines));
      Writeln('Blank lines: ' + IntToStrEx(fs.BlankLines));
      Writeln('Not blank lines: ' + IntToStrEx(fs.NotBlankLines));
      Writeln('');
    end;

  end;
end;

procedure TApp.ProcessFile(const FileName: string; var fs: TFileStats);
var
  sl: TStringList;
  i: integer;
  Line: string;
begin
  sl := TStringList.Create;
  try
    fs.FileSize := FileSizeInt(FileName);
    sl.LoadFromFile(FileName);
    fs.Lines += sl.Count;

    for i := 0 to sl.Count - 1 do
    begin
      Line := sl[i]; // or Trim(sl[i]);
      if Line = '' then fs.BlankLines += 1
      else fs.NotBlankLines += 1;
    end;

  finally
    sl.Free;
  end;
end;

procedure TApp.DisplaySummary;
begin
  if FStats.Files = 0 then Exit;
  Writeln('Command line: ' + CmdLine);
  Writeln('Processed files: ' + IntToStrEx(FStats.Files));
  Writeln('Total size: ' + GetFileSizeString(FStats.TotalSize));
  Writeln('Elapsed time: ' + AppParams.ElapsedTimeStr);
  Writeln('All lines: ' + IntToStrEx(FStats.Lines));
  Writeln('All blank lines: ' + IntToStrEx(FStats.BlankLines));
  TConsole.WriteTaggedTextLine('All not blank lines:<color=white,darkblue> ' + IntToStrEx(FStats.NotBlankLines) + ' </color>');
end;

{$endregion Main task}




{$region '                    Display... procs                  '}
procedure TApp.DisplayHelpAndExit(const ExCode: integer);
begin
  DisplayBanner;
  DisplayShortUsage;
  DisplayUsage;
  DisplayExtraInfo;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayShortUsageAndTerminate(const Msg: string; const ExCode: integer);
begin
  if Msg <> '' then
  begin
    if (ExCode = CON_EXIT_CODE_SYNTAX_ERROR) or (ExCode = CON_EXIT_CODE_ERROR) then DisplayError(Msg)
    else Writeln(Msg);
  end;
  DisplayShortUsage;
  DisplayTryHelp;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayShortUsageAndExit(const Msg: string; const ExCode: integer);
begin
  if Msg <> '' then Writeln(Msg);
  DisplayShortUsage;
  DisplayTryHelp;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayBannerAndExit(const ExCode: integer);
begin
  DisplayBanner;
  ExitCode := ExCode;
  Terminate;
end;

procedure TApp.DisplayMessageAndExit(const Msg: string; const ExCode: integer);
begin
  Writeln(Msg);
  ExitCode := ExCode;
  Terminate;
end;
{$endregion Display... procs}



end.
