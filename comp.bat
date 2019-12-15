@echo off
del %1.exe
del %1.obj
@echo on
ml /c %1.asm
link16 %1.obj,%1.exe,nul.map,.lib,nul.def
