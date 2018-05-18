@echo off

goto start1

:start

echo.
wait "CHYBA ..... Esc=preruseni: "
echo.
if errorlevel 1 goto konec

:start1

egacs k > NUL
cskey k > NUL
cd asm
kontext dm.asm #2  #1
cd ..
cskey ! > NUL
egacs ! > NUL

cd asm
make
if errorlevel == 1 goto start
cd ..

:konec
