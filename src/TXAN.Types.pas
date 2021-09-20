unit TXAN.Types;

{$IFDEF FPC}
  {$mode delphi}
{$ENDIF}

interface

uses
  SysUtils, Types,
  JPL.Strings;

type

  TFileStats = record
    FileSize: Int64;
    Lines: integer;
    BlankLines: integer;
    NotBlankLines: integer;
    procedure Clear;
  end;

  TTotalStats = record
    Files: integer;
    TotalSize: Int64;
    Lines: integer;
    BlankLines: integer;
    NotBlankLines: integer;
    procedure Clear;
    procedure AddFileStats(const fs: TFileStats; const IncFilesCount: Boolean = True);
  end;

  TAppParams = record
    FileMasks: TStringDynArray;
    IgnoreFileSymLinks: Boolean;
    IgnoreDirSymLinks: Boolean;
    RecursionDepth: Byte;
    Silent: Boolean;
    ShowSummary: Boolean;
    ElapsedTimeStr: string;
  end;


  
implementation



{ TTotalStats }

procedure TTotalStats.Clear;
begin
  Files := 0;
  Lines := 0;
  BlankLines := 0;
  NotBlankLines := 0;
end;

procedure TTotalStats.AddFileStats(const fs: TFileStats; const IncFilesCount: Boolean);
begin
  if IncFilesCount then Inc(Files);
  TotalSize += fs.FileSize;
  Lines += fs.Lines;
  BlankLines += fs.BlankLines;
  NotBlankLines += fs.NotBlankLines;
end;

{ TFileStats }

procedure TFileStats.Clear;
begin
  FileSize := 0;
  Lines := 0;
  BlankLines := 0;
  NotBlankLines := 0;
end;



end.
