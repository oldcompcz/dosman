@echo off

cd asm
make
if errorlevel == 1 goto konec
cd ..

:konec
