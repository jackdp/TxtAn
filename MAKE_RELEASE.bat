@echo off

set ArchFile=TxtAn.zip

if exist %ArchFile% del %ArchFile%

TxtAn64.exe > README.txt

7z a %ArchFile% TxtAn32.exe TxtAn64.exe README.txt

