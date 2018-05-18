@echo off
:start
egacs k > NUL
cskey k > NUL
kontext screen.asm 
egacs ! > NUL
cskey ! > NUL

tasm screen.asm screen.obj /z/zi/m5/t
if errorlevel == 1 goto chyba

tlink screen.obj, screen.ovl /t/l/s/x
if not errorlevel == 1 goto konec

:chyba
wait "CHYBA: Esc=preruseni, jina klavesa opakovani..."
if not errorlevel 1 goto start

:konec
del screen.obj
