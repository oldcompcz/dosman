@echo off
cls
tasm DOSMFLOP.ASM /z/zn/m5/t
tlink DOSMFLOP.OBJ /x/t
echo -------------------------------------
echo Ignorovat varovani "Open conditional"
echo -------------------------------------
del DOSMFLOP.OBJ
