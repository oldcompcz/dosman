@echo off
rem Pri zmene poctu nebo poradi stranek preloz DOSMAN cely znovu !!!!

:znovu
egacs k > NUL
cskey k > NUL
cd help
kontext help.txt
cd..
cskey ! > NUL
egacs ! > NUL

hlp_comp\hlp_comp.com
if not errorlevel 1 goto konec
echo.
wait "Esc=preruseni, jina klavesa opakovani..."
echo.
if errorlevel 1 goto konec
goto znovu

:konec
