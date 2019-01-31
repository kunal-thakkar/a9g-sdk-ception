@echo off
set TERMINFO=.\terminfo
set TERM=cygwin
arm-elf-gdb.exe %1 %2 %3 %4 %5
