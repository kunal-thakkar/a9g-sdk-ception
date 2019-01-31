@echo off
set TERMINFO=.\terminfo
set TERM=cygwin
arm-elf-insight.exe %1 %2 %3 %4 %5
