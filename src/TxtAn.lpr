program TxtAn;

{
  Jacek Pazera
  https://www.pazera-software.com
  https://github.com/jackdp

  First version (not published): May 2002
  -----------------------------------------
  TxtAn - A simple text files analyzer.
  The program counts the lines of text in the given text files.
  -----------------------------------------
}

{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads} cthreads, {$ENDIF}{$ENDIF}
  SysUtils,
  TXAN.App in 'TXAN.App.pas',
  TXAN.Types in 'TXAN.Types.pas';

var
  App: TApp;

{$IFDEF MSWINDOWS}
// Na Linuxie czasami wyskakuje EAccessViolation
//procedure MyExitProcedure;
//begin
//  if Assigned(App) then
//  begin
//    App.Done;
//    FreeAndNil(App);
//  end;
//end;
{$ENDIF}


{$R *.res}

begin
  {$IFDEF FPC}
    {$IF DECLARED(UseHeapTrace)}
	  GlobalSkipIfNoLeaks := True; // supported as of debugger version 3.2.0
    {$ENDIF}
  {$ENDIF}

  App := TApp.Create;
  try

    try

      //{$IFDEF MSWINDOWS}App.ExitProcedure := @MyExitProcedure;{$ENDIF}
      App.Init;
      App.Run;
      if Assigned(App) then App.Done;

    except
      on E: Exception do Writeln(E.ClassName, ': ', E.Message);
    end;

  finally
    if Assigned(App) then App.Free;
  end;

end.

