@echo off
tasm HLP_COMP.ASM /z/zn/m5/t
tlink HLP_COMP.OBJ /x/t
del HLP_COMP.OBJ
