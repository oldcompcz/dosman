
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;
;                              DOSMFLOP.ASM
;                          (c) Miroslav N늤e놽k
;                   Ovlada� rozÆ쯥n쁟h form쟴� disket.
;
; Tento program lze po p쯥kladu spustit jako program typu COM nebo jej um죛tit
; jako BOOT sektor diskety (je nutno ov쮍m p쯥psat z쟦lav� parametr� diskety).
; Lze jej t굫 za뇄enit do zdrojov괿o textu programu - v tom pæpad� se uvede:
;
; NOCOM   EQU       1                        ; pæznak pro p쯥klad jako INCLUDE
; INCLUDE DOSMFLOP.ASM                       ; vno쯥n� souboru DOSMFLOP.ASM
;
; Jako program COM se program p쯥lo몼 pomoc� pækaz�:
;
;  TASM DOSMFLOP
;  TLINK DOSMFLOP,DOSMFLOP.COM /t
;
; V쁲ledn� program DOSMFLOP.COM mus� m죜 po p쯥kladu velikost 512 bajt� !
; Program DOSMFLOP.COM lze spustit se zad쟮죑 parametru "1" nebo "2".
;
; Pozn.: Antivirov� kontrola BIOS kontroluje BOOT sektor, jestli se neprov쟡�
;        modifikace adresy DS:[413h] (velikost pam늯i v KB), proto je zde
;        tato operace skryt� adresov쟮죑 s SI.
;
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�


IFNDEF   NOCOM

Code     SEGMENT
         ASSUME    cs:Code,ds:Code
         ORG       100h

ENDIF

; -----------------------------------------------------------------------------
;        data BOOT sektoru (inicializa뇆� nastaveny parametry diskety 1.2 MB)
; -----------------------------------------------------------------------------

BootBeg  label     byte                     ; za뇿tek BOOT sektoru

         jmp       BootInit                 ; start a inicializace programu

BootOEM  db        'DOSMAN20'               ; identifikace

BootBytS dw        512                      ; d굃ka sektoru
BootClst db        1                        ; po놽t sektor� na aloka뇆� blok
BootRezS dw        1                        ; po놽t rezervovan쁟h sektor�
BootFATN db        2                        ; po놽t alok. tabulek FAT
BootRoot dw        224                      ; maxim쟫n� po놽t polo멷k ROOT
BootSumS dw        80*15*2                  ; celkov� po놽t sektor� disku
BootMedD db        0f9h                     ; popisova� m괺ia
BootFATS dw        7                        ; po놽t sektor� na FAT
BootSekt dw        15                       ; po놽t sektor� na stopu
BootSide dw        2                        ; po놽t stran disku
BootHidS dd        0                        ; skryt쁟h sektor� (2 nebo 4 bajty)
BootSumM dd        0                        ; celkem sektor� (4 bajty)

BootDisk db        0                        ; disk (pracovn�)
BootHead db        0                        ; hlava (pracovn�)

Boot29   db        29h                      ; identifik쟴or
BootSerN dd        0                        ; s굍iov� 눀slo disku

BootLabl db        'NO NAME    '            ; n쟶닲t� disku
BootLab0 label     byte                     ; adresa konce n쟶닲t� disku
BootFATT db        'FAT12   '               ; typ FAT

; -----------------------------------------------------------------------------
;        text v쁹vy k instalaci
; Nep쯥mis웣vat jinam - mus� b쁳 p쯥d BootIntX, aby tam skon뇁l registr SI !
; -----------------------------------------------------------------------------

BootTxt  db        13,10
         db        'Ovladac rozsirenych formatu disket - zvolte:',13,10
         db        ' [1]  = instalace',13,10
         db        ' [2]  = instalace se zamenou mechanik A a B',13,10
         db        'jinak = nic se neinstaluje',13,10
         db        0

; -----------------------------------------------------------------------------
;        obsluha INT 13h - z쟭늧a disk�
; -----------------------------------------------------------------------------

BootIntX PROC      FAR

; ------ test, zda to je disketa A: nebo B:

         cmp       dl,1                     ; maxim쟫n� 눀slo diskety
         ja        BootExec                 ; pokra뇇v쟮� p뻱odn� obsluhou

; ------ pro funkci 8 nen� pot쯥ba n쟶rat

         cmp       ah,8                     ; funkce poskytnut� parametr� ?
         je        BootInt1                 ; nebude se prov쟡늯 n쟶rat

; ------ obsluha po멲dovan� funkce

         push      dx                       ; 즧chova 눀sla disku
         pushf
         push      cs
         call      near ptr BootInt1        ; obsluha po멲dovan� funkce
         pop       dx                       ; n쟶rat p뻱odn죋o 눀sla disku
         ret       2

; ------ z쟭늧a disketov쁟h mechanik A: a B:

BootInt1:xor       dl,1                     ; z쟭늧a disketov쁟h mechanik

BootIntX ENDP
                                          ;* pokra뇎je BootIntY !

; -----------------------------------------------------------------------------
;        obsluha INT 13h - zv삩en� form쟴y disket
; -----------------------------------------------------------------------------

BootIntY PROC      FAR

; ------ kontrola, zda to je mechanika A: nebo B:

         cmp       dl,1                     ; maxim쟫n� 눀slo diskety
         ja        BootExec                 ; pokra뇇v쟮� p뻱odn� obsluhou

; ------ kontrola, zda je funkce 2 a� 4 (뇍en�, z쟰is, verifikace)

         cmp       ah,4
         ja        BootExec                 ; nen� funkce 2 a� 4
         cmp       ah,2
         jb        BootExec                 ; nen� funkce 2 a� 4

; ------ 즧chova registr�

         push      es
         push      cx
         push      bx
         push      ax

; ------ zv삩en� po뇍u sektor� na stopu

         xor       bx,bx                    ; BX <- 0
         mov       es,bx                    ; ES <- 0
         les       bx,es:[bx+4*1eh]         ; adresa tabulky INT 1Eh
         mov       byte ptr es:[bx+4],46    ; zv삩en� po뇍u sektor� na stopu

; ------ inicializace registr� na data BIOS

         mov       bx,40h                   ; BX <- 40h
         mov       es,bx                    ; ES <- 40h

; ------ test, zda je m괺ium ji� ur놽no

         add       bl,dl                    ; korekce na 눀slo disku
         test      byte ptr es:[bx-40h+90h],10h ; je m괺ium ji� ur놽no ?
         jnz       BootInt8                 ; je ji� ur놽no

; ------ m괺ium ur놽no

         or        byte ptr es:[bx-40h+90h],10h ; te� ji� je ur놽no

; ------ test, zda je rychlost nastavena OK (nyn� je ES=40h, BX=40h a� 41h)

         mov       cx,200h                  ; CH <- stopa, CL <- sektor
BootInt3:inc       cx                       ; CL <- zv삩en� 눀sla sektoru
         mov       ax,401h                  ; verifikace 1 sektoru
         push      bx                       ; 즧chova offsetu v BIOS
         push      cx                       ; 즧chova stopy a sektoru
         push      dx                       ; 즧chova disku a strany
         pushf                              ; simulace instrukce INT ...
         push      cs                       ; simulace instrukce CALL FAR ...
         call      BootExec                 ; verifikace sektoru
         pop       dx                       ; n쟶rat disku a strany
         pop       cx                       ; n쟶rat stopy a sektoru
         pop       bx                       ; n쟶rat offsety v BIOS
         jnc       Bootint8                 ; rychlost detekov쟮a OK

; ------ chyba v쁬늧y m괺ia nebo disk nep쯫praven - okam멼t� ukon놽n�

         cmp       ah,6
         je        BootInt9                 ; v쁬늧a diskety
         or        ah,ah                    ; chyba 80h ?
         js        BootInt9                 ; mechanika nep쯫pravena

; ------ zv삩en� rychlosti (cyklus 500 > 300 > 250 > 1000)

         add       byte ptr es:[bx-40h+90h],40h ; zv삩en� rychlosti
         test      cl,3                     ; je sektor 4 nebo 8 ?
         jnz       BootInt3                 ; nen� sektor 4 ani 8

; ------ zm늧a krokov쟮� (p쯫 sektorech 4 a 8) (dvojit� a jednoduch�)
; Krokov쟮� se m늧� a� po zm늧쟠h rychlosti, aby po찤d nevystavovala mechanika

         xor       byte ptr es:[bx-40h+90h],20h ; zm늧a krokov쟮�
         cmp       cl,8                     ; je ji� maximum test� ?
         jb        BootInt3                 ; nen� je쮝� maximum test�

; ------ m괺ium neur놽no

         and       byte ptr es:[bx-40h+90h],not 10h ; m괺ium neur놽no

; ------ n쟶rat registr�

BootInt8:pop       ax
         pop       bx
         pop       cx
         pop       es

; ------ pokra뇇v쟮� p뻱odn� obsluhou

BootExec:db        0eah                     ; instrukce JMP FAR
BootOld  dd        0                        ; p뻱odn� adresa INT 13h

; ------ n쟶rat p쯫 chyb� 6 (v쁬늧a diskety) a 80h (nen� vlo멷na disketa)

BootInt9:and       byte ptr es:[bx-40h+90h],not 10h ; m괺ium neur놽no
         pop       bx                       ; ponech� se reg. AX - chybov� k줰
         pop       bx
         pop       cx
         pop       es
         stc                                ; pæznak chyby
         ret       2                        ; tento n쟶rat pou몼v� i BIOS

BootIntY ENDP

BootREnd label     byte                     ; konec rezidentn죋o modulu

; -----------------------------------------------------------------------------
;        start a inicializace programu
; -----------------------------------------------------------------------------

; ------ rozli쮍n�, zda je BOOT nebo COM

BootInit:mov       ax,cs                    ; AX <- CS
         or        ax,ax                    ; je to BOOT sektor ?
         jnz       BootInC                  ; je jako COM

; -----------------------------------------------------------------------------
;        instalace jako BOOT
;   Nyn� je cel� zavad늾 na adrese 0:7C00h !!!
; -----------------------------------------------------------------------------

; ------ p쯥definov쟮� z쟳obn죏u (p쯥d BOOT sektor)

         mov       si,413h                  ; offset velikosti pam늯i v KB
         mov       ds,ax                    ; DS <- 0
         mov       ss,ax                    ; SS <- 0
         mov       sp,7c00h                 ; offset z쟳obn죏u p쯥d programem

; ------ adresa rezidentu (nepou몼vat mov ax,ds:[413h] - antiviry !) -> ES:DI

         dec       word ptr ds:[si]         ; sn죷en� velikosti pam늯i o 1 KB
         mov       di,ds:[si]               ; aktu쟫n� velikost pam늯i v KB
         mov       cl,6                     ; CL <- po놽t rotac� pro p쯥po놽t
         shl       di,cl                    ; p쯥po놽t KB na odstavce
         mov       es,di                    ; ES <- segment rezidentu
         xor       di,di                    ; DI <- offset rezidentu

; ------ volba operace (zde je AL = 0 a DS=CS)

         call      BootInst                 ; volba instalace

; ------ n쟶rat velikosti pam늯i p쯫 p쯥ru쮍n� (je nastaven CY, CS=0)

         adc       word ptr cs:[413h],0     ; p쯫 p쯥ru쮍n� CY n쟶rat pam늯i

; ------ pokra뇇v쟮� v zav쟡늧� syst굆u

         int       19h
         hlt                                ; to jen pro jistotu, ale nen� t쯥ba

; -----------------------------------------------------------------------------
;        instalace jako COM
; -----------------------------------------------------------------------------

; ------ adresa k p쯥sunu (ES=CS, DS=CS !)

BootInC: mov       di,5ch                   ; adresa k p쯥sunu

; ------ nalezen� znaku v pækazov굆 찤dku

         mov       si,81h                   ; buffer pækazov괿o 찤dku
         cld
BootInC2:lodsb                              ; na뇍en� znaku z pækazov괿o 찤dku
         cmp       al," "                   ; je odd늢ovac� mezera ?
         je        BootInC2                 ; odd늢ovac� mezera - dalÆ znak

; ------ volba operace

         call      BootInst                 ; volba instalace
         jnc       BootInC4                 ; instaluje se OK
         int       20h                      ; p쯥ru쮍n� programu

; ------ uvoln늧� segmentu prost쯥d� (DS=CS !)

BootInC4:mov       es,ds:[2ch]              ; segment prost쯥d�
         mov       ah,49h
         int       21h                      ; uvoln늧� segmentu prost쯥d�

; ------ instalace programu do pam늯i (DI=adresa konce rezidentu !)

         mov       dx,di                    ; konec programu
         int       27h                      ; instalace

; -----------------------------------------------------------------------------
; instalace obsluhy INT 13h (AL=znak, ES:DI=za뇿tek rezidentu) -> CY=p쯥ru쮍n�
; -----------------------------------------------------------------------------
; VSTUP: AL=znak z pækazov괿o 찤dku (pro BOOT sektor je AL=0)
;        ES:DI=adresa k ulo멷n� rezidentn� obsluhy
;        DS=CS
; V쒾TUP: ES:DI=adresa konce p쯥nesen괿o rezidentu
;         DS=CS (pouze pro NC = operace OK)
;         CY=p쯥ru쮍n� instalace
; -----------------------------------------------------------------------------

BootInst PROC      NEAR

; ------ zobrazen� textu

         push      ax                       ; 즧chova znaku z pækaz. 찤dku

         call      BootIns2                 ; n쟶ratov� adresa do z쟳obn죏u
BootIns2:pop       si                       ; SI <- adresa BootIns2
         sub       si,offset(BootIns2-BootTxt) ; adresa textu
BootIns4:cld
         lodsb
         or        al,al
         jz        BootIns6
         push      si                       ; (instrukci lze asi zru쮑t)
         mov       ah,0eh
         mov       bx,7
         int       10h
         pop       si                       ; (instrukci lze asi zru쮑t)
         jmp       short BootIns4

BootIns6:pop       ax                       ; znak z pækazov괿o 찤dku

; ------ 놽k쟮� na stisk kl쟶esy (SI=adresa za뇿tku INT 13h)

         cmp       al," "                   ; byl zad쟮 n늞ak� znak ?
         ja        BootIns7                 ; byl zad쟮 n늞ak� znak
         xor       ax,ax
         int       16h                      ; vstup znaku z kl쟶esnice

; ------ segment vektor� p쯥ru쮍n�

BootIns7:xor       bx,bx
         mov       ds,bx                    ; DS <- 0

; ------ test, zda bude instalace volbou "1" nebo "2"

         cmp       al,"2"+1
         cmc
         jc        BootIns9                 ; nespr쟶n� volba
         cmp       al,"1"
         jb        BootIns9                 ; nespr쟶n� volba

; ------ 즧chova p뻱odn� adresy INT 13h (tady je ZY=je instalace 1 !)

         mov       ax,ds:[bx+4*13h]         ; offset adresy INT 13h
         mov       word ptr cs:[si+BootOld-BootIntX],ax ; 즧chova offsetu adresy
         mov       ax,ds:[bx+4*13h+2]       ; segment adresy INT 13h
         mov       word ptr cs:[si+BootOld-BootIntX+2],ax ; 즧chova segmentu

; ------ instalace nov� obsluhy INT 13h

         mov       ds:[bx+4*13h],di         ; offset rezidentu
         mov       ds:[bx+4*13h+2],es       ; segment rezidentu

; ------ instalace pro volby "1" - rozÆ쯥n� form쟴y

         mov       cx,offset(BootREnd-BootIntX) ; d굃ka dat k p쯥sunu
         ja        BootIns8                 ; byla volba "2" - z쟭늧a mechanik
         add       si,offset(BootIntY-BootIntX)
         mov       cl,offset(BootREnd-BootIntY)

; ------ p쯥nesen� rezidentn� 뇿sti (zde je NC !)

BootIns8:cld
         push      cs
         pop       ds                       ; DS <- CS
         rep       movsb                    ; posun programu dol�
BootIns9:ret

BootInst ENDP

;         db        0 dup(0)                ; dopln늟 na 512 B

BootIdnt dw        0aa55h                   ; pæznak BOOT sektoru

BootEnd  label     byte                     ; konec BOOT sektoru


IFNDEF   NOCOM

Code     ENDS
                                          ;* p쯫 p쯥kladu jako COM hl쟳�
                                          ;* varov쟮�, 멷 je otev쯥n� podm죒ka
                                          ;* - to se mus� ignorovat
         END       BootBeg
ENDIF
