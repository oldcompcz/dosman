
; �����������������������������������������������������������������������������
;
;                              DOSMFLOP.ASM
;                          (c) Miroslav N�me�ek
;                   Ovlada� roz���en�ch form�t� disket.
;
; Tento program lze po p�ekladu spustit jako program typu COM nebo jej um�stit
; jako BOOT sektor diskety (je nutno ov�em p�epsat z�hlav� parametr� diskety).
; Lze jej t�� za�lenit do zdrojov�ho textu programu - v tom p��pad� se uvede:
;
; NOCOM   EQU       1                        ; p��znak pro p�eklad jako INCLUDE
; INCLUDE DOSMFLOP.ASM                       ; vno�en� souboru DOSMFLOP.ASM
;
; Jako program COM se program p�elo�� pomoc� p��kaz�:
;
;  TASM DOSMFLOP
;  TLINK DOSMFLOP,DOSMFLOP.COM /t
;
; V�sledn� program DOSMFLOP.COM mus� m�t po p�ekladu velikost 512 bajt� !
; Program DOSMFLOP.COM lze spustit se zad�n�m parametru "1" nebo "2".
;
; Pozn.: Antivirov� kontrola BIOS kontroluje BOOT sektor, jestli se neprov�d�
;        modifikace adresy DS:[413h] (velikost pam�ti v KB), proto je zde
;        tato operace skryt� adresov�n�m s SI.
;
; �����������������������������������������������������������������������������


IFNDEF   NOCOM

Code     SEGMENT
         ASSUME    cs:Code,ds:Code
         ORG       100h

ENDIF

; -----------------------------------------------------------------------------
;        data BOOT sektoru (inicializa�n� nastaveny parametry diskety 1.2 MB)
; -----------------------------------------------------------------------------

BootBeg  label     byte                     ; za��tek BOOT sektoru

         jmp       BootInit                 ; start a inicializace programu

BootOEM  db        'DOSMAN20'               ; identifikace

BootBytS dw        512                      ; d�lka sektoru
BootClst db        1                        ; po�et sektor� na aloka�n� blok
BootRezS dw        1                        ; po�et rezervovan�ch sektor�
BootFATN db        2                        ; po�et alok. tabulek FAT
BootRoot dw        224                      ; maxim�ln� po�et polo�ek ROOT
BootSumS dw        80*15*2                  ; celkov� po�et sektor� disku
BootMedD db        0f9h                     ; popisova� m�dia
BootFATS dw        7                        ; po�et sektor� na FAT
BootSekt dw        15                       ; po�et sektor� na stopu
BootSide dw        2                        ; po�et stran disku
BootHidS dd        0                        ; skryt�ch sektor� (2 nebo 4 bajty)
BootSumM dd        0                        ; celkem sektor� (4 bajty)

BootDisk db        0                        ; disk (pracovn�)
BootHead db        0                        ; hlava (pracovn�)

Boot29   db        29h                      ; identifik�tor
BootSerN dd        0                        ; s�riov� ��slo disku

BootLabl db        'NO NAME    '            ; n�v��t� disku
BootLab0 label     byte                     ; adresa konce n�v��t� disku
BootFATT db        'FAT12   '               ; typ FAT

; -----------------------------------------------------------------------------
;        text v�zvy k instalaci
; Nep�emis�ovat jinam - mus� b�t p�ed BootIntX, aby tam skon�il registr SI !
; -----------------------------------------------------------------------------

BootTxt  db        13,10
         db        'Ovladac rozsirenych formatu disket - zvolte:',13,10
         db        ' [1]  = instalace',13,10
         db        ' [2]  = instalace se zamenou mechanik A a B',13,10
         db        'jinak = nic se neinstaluje',13,10
         db        0

; -----------------------------------------------------------------------------
;        obsluha INT 13h - z�m�na disk�
; -----------------------------------------------------------------------------

BootIntX PROC      FAR

; ------ test, zda to je disketa A: nebo B:

         cmp       dl,1                     ; maxim�ln� ��slo diskety
         ja        BootExec                 ; pokra�ov�n� p�vodn� obsluhou

; ------ pro funkci 8 nen� pot�eba n�vrat

         cmp       ah,8                     ; funkce poskytnut� parametr� ?
         je        BootInt1                 ; nebude se prov�d�t n�vrat

; ------ obsluha po�adovan� funkce

         push      dx                       ; �schova ��sla disku
         pushf
         push      cs
         call      near ptr BootInt1        ; obsluha po�adovan� funkce
         pop       dx                       ; n�vrat p�vodn�ho ��sla disku
         ret       2

; ------ z�m�na disketov�ch mechanik A: a B:

BootInt1:xor       dl,1                     ; z�m�na disketov�ch mechanik

BootIntX ENDP
                                          ;* pokra�uje BootIntY !

; -----------------------------------------------------------------------------
;        obsluha INT 13h - zv��en� form�ty disket
; -----------------------------------------------------------------------------

BootIntY PROC      FAR

; ------ kontrola, zda to je mechanika A: nebo B:

         cmp       dl,1                     ; maxim�ln� ��slo diskety
         ja        BootExec                 ; pokra�ov�n� p�vodn� obsluhou

; ------ kontrola, zda je funkce 2 a� 4 (�ten�, z�pis, verifikace)

         cmp       ah,4
         ja        BootExec                 ; nen� funkce 2 a� 4
         cmp       ah,2
         jb        BootExec                 ; nen� funkce 2 a� 4

; ------ �schova registr�

         push      es
         push      cx
         push      bx
         push      ax

; ------ zv��en� po�tu sektor� na stopu

         xor       bx,bx                    ; BX <- 0
         mov       es,bx                    ; ES <- 0
         les       bx,es:[bx+4*1eh]         ; adresa tabulky INT 1Eh
         mov       byte ptr es:[bx+4],46    ; zv��en� po�tu sektor� na stopu

; ------ inicializace registr� na data BIOS

         mov       bx,40h                   ; BX <- 40h
         mov       es,bx                    ; ES <- 40h

; ------ test, zda je m�dium ji� ur�eno

         add       bl,dl                    ; korekce na ��slo disku
         test      byte ptr es:[bx-40h+90h],10h ; je m�dium ji� ur�eno ?
         jnz       BootInt8                 ; je ji� ur�eno

; ------ m�dium ur�eno

         or        byte ptr es:[bx-40h+90h],10h ; te� ji� je ur�eno

; ------ test, zda je rychlost nastavena OK (nyn� je ES=40h, BX=40h a� 41h)

         mov       cx,200h                  ; CH <- stopa, CL <- sektor
BootInt3:inc       cx                       ; CL <- zv��en� ��sla sektoru
         mov       ax,401h                  ; verifikace 1 sektoru
         push      bx                       ; �schova offsetu v BIOS
         push      cx                       ; �schova stopy a sektoru
         push      dx                       ; �schova disku a strany
         pushf                              ; simulace instrukce INT ...
         push      cs                       ; simulace instrukce CALL FAR ...
         call      BootExec                 ; verifikace sektoru
         pop       dx                       ; n�vrat disku a strany
         pop       cx                       ; n�vrat stopy a sektoru
         pop       bx                       ; n�vrat offsety v BIOS
         jnc       Bootint8                 ; rychlost detekov�na OK

; ------ chyba v�m�ny m�dia nebo disk nep�ipraven - okam�it� ukon�en�

         cmp       ah,6
         je        BootInt9                 ; v�m�na diskety
         or        ah,ah                    ; chyba 80h ?
         js        BootInt9                 ; mechanika nep�ipravena

; ------ zv��en� rychlosti (cyklus 500 > 300 > 250 > 1000)

         add       byte ptr es:[bx-40h+90h],40h ; zv��en� rychlosti
         test      cl,3                     ; je sektor 4 nebo 8 ?
         jnz       BootInt3                 ; nen� sektor 4 ani 8

; ------ zm�na krokov�n� (p�i sektorech 4 a 8) (dvojit� a jednoduch�)
; Krokov�n� se m�n� a� po zm�n�ch rychlosti, aby po��d nevystavovala mechanika

         xor       byte ptr es:[bx-40h+90h],20h ; zm�na krokov�n�
         cmp       cl,8                     ; je ji� maximum test� ?
         jb        BootInt3                 ; nen� je�t� maximum test�

; ------ m�dium neur�eno

         and       byte ptr es:[bx-40h+90h],not 10h ; m�dium neur�eno

; ------ n�vrat registr�

BootInt8:pop       ax
         pop       bx
         pop       cx
         pop       es

; ------ pokra�ov�n� p�vodn� obsluhou

BootExec:db        0eah                     ; instrukce JMP FAR
BootOld  dd        0                        ; p�vodn� adresa INT 13h

; ------ n�vrat p�i chyb� 6 (v�m�na diskety) a 80h (nen� vlo�ena disketa)

BootInt9:and       byte ptr es:[bx-40h+90h],not 10h ; m�dium neur�eno
         pop       bx                       ; ponech� se reg. AX - chybov� k�d
         pop       bx
         pop       cx
         pop       es
         stc                                ; p��znak chyby
         ret       2                        ; tento n�vrat pou��v� i BIOS

BootIntY ENDP

BootREnd label     byte                     ; konec rezidentn�ho modulu

; -----------------------------------------------------------------------------
;        start a inicializace programu
; -----------------------------------------------------------------------------

; ------ rozli�en�, zda je BOOT nebo COM

BootInit:mov       ax,cs                    ; AX <- CS
         or        ax,ax                    ; je to BOOT sektor ?
         jnz       BootInC                  ; je jako COM

; -----------------------------------------------------------------------------
;        instalace jako BOOT
;   Nyn� je cel� zavad�� na adrese 0:7C00h !!!
; -----------------------------------------------------------------------------

; ------ p�edefinov�n� z�sobn�ku (p�ed BOOT sektor)

         mov       si,413h                  ; offset velikosti pam�ti v KB
         mov       ds,ax                    ; DS <- 0
         mov       ss,ax                    ; SS <- 0
         mov       sp,7c00h                 ; offset z�sobn�ku p�ed programem

; ------ adresa rezidentu (nepou��vat mov ax,ds:[413h] - antiviry !) -> ES:DI

         dec       word ptr ds:[si]         ; sn��en� velikosti pam�ti o 1 KB
         mov       di,ds:[si]               ; aktu�ln� velikost pam�ti v KB
         mov       cl,6                     ; CL <- po�et rotac� pro p�epo�et
         shl       di,cl                    ; p�epo�et KB na odstavce
         mov       es,di                    ; ES <- segment rezidentu
         xor       di,di                    ; DI <- offset rezidentu

; ------ volba operace (zde je AL = 0 a DS=CS)

         call      BootInst                 ; volba instalace

; ------ n�vrat velikosti pam�ti p�i p�eru�en� (je nastaven CY, CS=0)

         adc       word ptr cs:[413h],0     ; p�i p�eru�en� CY n�vrat pam�ti

; ------ pokra�ov�n� v zav�d�n� syst�mu

         int       19h
         hlt                                ; to jen pro jistotu, ale nen� t�eba

; -----------------------------------------------------------------------------
;        instalace jako COM
; -----------------------------------------------------------------------------

; ------ adresa k p�esunu (ES=CS, DS=CS !)

BootInC: mov       di,5ch                   ; adresa k p�esunu

; ------ nalezen� znaku v p��kazov�m ��dku

         mov       si,81h                   ; buffer p��kazov�ho ��dku
         cld
BootInC2:lodsb                              ; na�ten� znaku z p��kazov�ho ��dku
         cmp       al," "                   ; je odd�lovac� mezera ?
         je        BootInC2                 ; odd�lovac� mezera - dal�� znak

; ------ volba operace

         call      BootInst                 ; volba instalace
         jnc       BootInC4                 ; instaluje se OK
         int       20h                      ; p�eru�en� programu

; ------ uvoln�n� segmentu prost�ed� (DS=CS !)

BootInC4:mov       es,ds:[2ch]              ; segment prost�ed�
         mov       ah,49h
         int       21h                      ; uvoln�n� segmentu prost�ed�

; ------ instalace programu do pam�ti (DI=adresa konce rezidentu !)

         mov       dx,di                    ; konec programu
         int       27h                      ; instalace

; -----------------------------------------------------------------------------
; instalace obsluhy INT 13h (AL=znak, ES:DI=za��tek rezidentu) -> CY=p�eru�en�
; -----------------------------------------------------------------------------
; VSTUP: AL=znak z p��kazov�ho ��dku (pro BOOT sektor je AL=0)
;        ES:DI=adresa k ulo�en� rezidentn� obsluhy
;        DS=CS
; V�STUP: ES:DI=adresa konce p�enesen�ho rezidentu
;         DS=CS (pouze pro NC = operace OK)
;         CY=p�eru�en� instalace
; -----------------------------------------------------------------------------

BootInst PROC      NEAR

; ------ zobrazen� textu

         push      ax                       ; �schova znaku z p��kaz. ��dku

         call      BootIns2                 ; n�vratov� adresa do z�sobn�ku
BootIns2:pop       si                       ; SI <- adresa BootIns2
         sub       si,offset(BootIns2-BootTxt) ; adresa textu
BootIns4:cld
         lodsb
         or        al,al
         jz        BootIns6
         push      si                       ; (instrukci lze asi zru�it)
         mov       ah,0eh
         mov       bx,7
         int       10h
         pop       si                       ; (instrukci lze asi zru�it)
         jmp       short BootIns4

BootIns6:pop       ax                       ; znak z p��kazov�ho ��dku

; ------ �ek�n� na stisk kl�vesy (SI=adresa za��tku INT 13h)

         cmp       al," "                   ; byl zad�n n�jak� znak ?
         ja        BootIns7                 ; byl zad�n n�jak� znak
         xor       ax,ax
         int       16h                      ; vstup znaku z kl�vesnice

; ------ segment vektor� p�eru�en�

BootIns7:xor       bx,bx
         mov       ds,bx                    ; DS <- 0

; ------ test, zda bude instalace volbou "1" nebo "2"

         cmp       al,"2"+1
         cmc
         jc        BootIns9                 ; nespr�vn� volba
         cmp       al,"1"
         jb        BootIns9                 ; nespr�vn� volba

; ------ �schova p�vodn� adresy INT 13h (tady je ZY=je instalace 1 !)

         mov       ax,ds:[bx+4*13h]         ; offset adresy INT 13h
         mov       word ptr cs:[si+BootOld-BootIntX],ax ; �schova offsetu adresy
         mov       ax,ds:[bx+4*13h+2]       ; segment adresy INT 13h
         mov       word ptr cs:[si+BootOld-BootIntX+2],ax ; �schova segmentu

; ------ instalace nov� obsluhy INT 13h

         mov       ds:[bx+4*13h],di         ; offset rezidentu
         mov       ds:[bx+4*13h+2],es       ; segment rezidentu

; ------ instalace pro volby "1" - roz���en� form�ty

         mov       cx,offset(BootREnd-BootIntX) ; d�lka dat k p�esunu
         ja        BootIns8                 ; byla volba "2" - z�m�na mechanik
         add       si,offset(BootIntY-BootIntX)
         mov       cl,offset(BootREnd-BootIntY)

; ------ p�enesen� rezidentn� ��sti (zde je NC !)

BootIns8:cld
         push      cs
         pop       ds                       ; DS <- CS
         rep       movsb                    ; posun programu dol�
BootIns9:ret

BootInst ENDP

;         db        0 dup(0)                ; dopln�k na 512 B

BootIdnt dw        0aa55h                   ; p��znak BOOT sektoru

BootEnd  label     byte                     ; konec BOOT sektoru


IFNDEF   NOCOM

Code     ENDS
                                          ;* p�i p�ekladu jako COM hl�s�
                                          ;* varov�n�, �e je otev�en� podm�nka
                                          ;* - to se mus� ignorovat
         END       BootBeg
ENDIF
