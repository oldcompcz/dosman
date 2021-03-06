
INCLUDE  DEF.ASM

; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;
;
;                              Z쟳obn죏
;
; Tento z쟳obn죏 se pou몼v� jako z쟳obn죏 pouze p쯫 inicializaci DOS Mana멷ru
; a p쯫 startu jin괿o programu. Mus� b쁳 p쯫linkov쟮 jako prvn� segment.
;
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�

StackS   SEGMENT   PARA STACK 'STACK'

         db        256/8 dup('Zasobnik')    ; p쯥chodn� z쟳obn죏
                                            ; (velikost zachovat - nastavuje
                                            ; se pæmo 눀seln� v programu)

StackS   ENDS

; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;
;                           L O A D E R
;
;                   zavad늾 programu DOS Mana멷r
; -----------------------------------------------------------------------------
; tento modul mus� b쁳 nalinkov쟮 v멶y jako prvn� z programov쁟h modul�
;
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�


CodeLod  SEGMENT   BYTE PUBLIC
         ASSUME    cs:CodeLod,ds:DATA

LoadBeg  LABEL     BYTE                     ; za뇿tek zavad늾e k identifikaci

; -----------------------------------------------------------------------------
;        start programu - parametry v pækazov굆 찤dku
; -----------------------------------------------------------------------------

Execute  LABEL     FAR

; ------ zmen쮍n� velikosti bloku programu

         mov       bx,offset ConfEnd + 15
         mov       cl,4
         shr       bx,cl
         add       bx,SEG Data              ; adresa konec dat
         mov       es,ds:[SegPSP]           ; segment PSP
         sub       bx,ds:[SegPSP]           ; velikost programu
         mov       ah,4ah
         int       21h                      ; zmen쮍n� bloku programu

; ------ p쯥definov쟮� INT 24h

Execute1:push      ds
         push      cs
         pop       ds
         mov       dx,offset INT024
         mov       ax,2524h
         int       21h                      ; p쯥definov쟮� INT 24h

; ------ p쯥definov쟮� INT 23h

         mov       dx,offset INT023
         mov       ax,2523h
         int       21h                      ; p쯥definov쟮� INT 23h
         pop       ds

; ------ start programu (DS=datov� segment)

         push      ds
         pop       es
         mov       dx,offset ExecPath       ; cesta k programu
         mov       bx,offset ExecPack       ; paket parametr�
         mov       ax,4b00h
         int       21h                      ; start programu

; ------ obnoven� ukazatele z쟳obn죏u

         mov       ax,SEG StackS            ; segment z쟳obn죏u
         mov       ss,ax                    ; segment z쟳obn죏u
         mov       sp,256                   ; adresa konce z쟳obn죏u
         jnc       Execute5                 ; operace OK

; ------ opakov쟮� operace

         mov       dx,offset ErrCMTxt
         call      ExecErr
         jnc       Execute1

; ------ p쯥definov쟮� INT 24h

Execute5:push      cs
         pop       ds
         mov       dx,offset INT024
         mov       ax,2524h
         int       21h                      ; p쯥definov쟮� INT 24h

; ------ p쯥definov쟮� INT 23h

         mov       dx,offset INT023
         mov       ax,2523h
         int       21                       ; p쯥definov쟮� INT 23h

; ------ obnoven� registr�

         mov       ax,SEG Data              ; datov� segment
         mov       ds,ax                    ; DS <- datov� segment
         mov       es,ax
         mov       ds:[ExecPck1],ax         ; segment pækazov괿o 찤dku
         mov       word ptr ds:[ExecPck0],offset RezIdent ; tabulka identifikace

; ------ nov� start programu

         mov       dx,offset DosmPath
         mov       bx,offset ExecPack
         mov       ax,4b00h
         int       21h

; ------ obnoven� ukazatele z쟳obn죏u

         mov       ax,SEG StackS            ; segment z쟳obn죏u
         mov       ss,ax                    ; segment z쟳obn죏u
         mov       sp,256                   ; adresa konce z쟳obn죏u

; ------ obnoven� registr�

         mov       ax,SEG Data              ; datov� segment
         mov       ds,ax                    ; DS <- datov� segment
         jc        Execute8                 ; chyba operace

; ------ test, zda bylo chybov� p쯥ru쮍n�

         mov       ah,4dh
         int       21h                      ; poskytnut� n쟶ratov괿o k줰u
         cmp       ax,2                     ; je chyba ?
         jae       Execut82                 ; je chyba

; ------ rozli쮍n�, zda je dalÆ pækaz

         mov       es,ds:[SegPSP]
         cmp       byte ptr es:[80h],1      ; je konec programu ?
         mov       al,1                     ; pæznak konce programu
         jb        Execute9                 ; konec
         mov       al,0                     ; pæznak povelov괿o souboru
         je        Execute9                 ; je povelov� soubor
         jmp       Execute1                 ; dalÆ pækaz

; ------ chyba - nelze zav굎t DOSMAN

Execute8:mov       dx,offset ErrDMTxt
         call      ExecErr
         jnc       Execute5
Execut82:mov       al,2

; ------ konec programu

Execute9:mov       ah,4ch
         int       21h

LoadEnd  LABEL     BYTE                     ; konec zavad늾e k identifikaci

; -----------------------------------------------------------------------------
;        hl젴en� chyby DX a pæp. opakov쟮� operace
; -----------------------------------------------------------------------------

ExecErr  PROC      NEAR

         mov       ah,9
         int       21h

         mov       dx,offset ZnovuTxt
         mov       ah,9
         int       21h

ExecErr1:mov       ah,8
         int       21h
         or        al,al
         jnz       ExecErr2
         mov       ah,8
         int       21h

ExecErr2:cmp       al,CR
         je        ExecErr3
         cmp       al,ESCP
         jne       ExecErr1
         stc
ExecErr3:ret

ExecErr  ENDP

; -----------------------------------------------------------------------------
;        p쯥chodn� obsluha INT 24h a INT 23h
; -----------------------------------------------------------------------------

Int024   PROC      FAR

         mov       al,0

Int023   LABEL     FAR

         iret

Int024   ENDP

CodeLod  ENDS

; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;
;
;                                 Data
;
;
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;�
Data     SEGMENT

DataBeg  LABEL     BYTE                     ; za뇿tek dat

; ------ hl젴en� - COMMAND/DOSMAN nelze zav굎t

ErrCMTxt db        'Program$'
ErrDMTxt db        'DOSMAN$'
ZnovuTxt db        ' nelze zavest do pameti !'
         db        13,10,'Stisknete: ENTER=opakovani, ESC=konec...$'

; ------ identifikace rezidentn죋o modulu DOSMAN.EXE v pækazov굆 찤dku

RezIdent db        10,'<DM>'                ; d굃ka 찤dku + identifikace
SegPSP   dw        0                        ; segment PSP
SegData  dw        SEG Data                 ; datov� segment
SegLoad  dw        SEG CodeLod              ; segment zavad늾e

; ------ paket pro spu쮝늧� programu

ExecPack label     word                     ; paket pro spu쮝늧� programu
ExecPckE dw        0                        ; adresa segmentu prost쯥d�
ExecPck0 dw        80h                      ; offset pækazov괿o 찤dku
ExecPck1 dw        0                        ; segment pækazov괿o 찤dku
         dw        5ch                      ; offset prvn죋o FCB
ExecPck2 dw        0                        ; segment prvn죋o FCB
         dw        6ch                      ; offset druh괿o FCB
ExecPck3 dw        0                        ; segment druh괿o FCB

; ------ cesta ke spou쮝늧굆u programu

ExecPath label     byte
         db        FileMax dup(0)           ; spou쮝늧� program (COMMAND.COM...)
DosmPath label     byte
         db        FileMax dup(0)           ; n쟶ratov� cesta k DOSMAN.EXE
DosmPth0 label     byte

; *****************************************************************************
;
;             Konfigurace (uchov쟮o v pam늯i a ukl쟡� se na disk)
;
; *****************************************************************************
;�
ConfBeg  LABEL     BYTE                     ; za뇿tek konfigurace (rezid. data)

; ------ identifikace datov괿o modulu

ConfIdnt db        'D'                      ; identifikace modulu dat
         db        DMVerze1 XOR 21h         ; hlavn� 눀slo verze
         db        DMVerze2 XOR 46h         ; desetiny 눀sla verze
         db        DMVerze3 XOR 83h         ; setiny 눀sla verze

ConfSumm dw        0                        ; kontroln� sou놽t modulu dat

; -----------------------------------------------------------------------------
;        displej
; -----------------------------------------------------------------------------

InitVMd  db        80,25                    ; rozm늭y po멲dovan괿o videom줰u

ParDisp2 db        bit5                     ; parametry displeje 2
                                            ;   bit 0: 1=blik쟮� pozad� znak�
                                            ;   bit 1: 1=zv삩en� intenzita znak�
                                            ;   bit 2: 1=blik쟮� znak� DOS
                                            ;   bit 3: 1=zv삩en� intenzita DOS
                                            ;   bit 4: 1=pou몼t 쮍d� palety VGA
                                            ;   bit 5: 1=pou몼t vlastn� fonty
                                            ;   bit 6: 1=okno WINDOWS

MonoMod  db        0                        ; pæznak barev
                                            ;   bit 0: 1=po멲davek MONO (LCD)
                                            ;   bit 1: 1=MONO videom줰

                                            ;   bit 4: 1=je v쁲tup ANSI

CodePag0 db        0                        ; u멼vatelsky zadan� k줰ov� str쟮ka
                                            ;    0 = nezad쟮o
                                            ;    1 = bez diakritiky
                                            ;    2 = IBM (omezen� diakritika)
                                            ;    3 = KEYBCS2 (Kamenick쁟h)
                                            ;    4 = Latin 2

; -----------------------------------------------------------------------------
;        즧chova aktivn죅h polo멷k menu
; -----------------------------------------------------------------------------

UschMenu label     byte
         db        31 dup(1)                ; tabulka aktivn죅h polo멷k menu

UserLast label     word
         dw        MaxUserM dup(0)          ; uschovan� volby u멼v. menu

; -----------------------------------------------------------------------------
;        DBF
; -----------------------------------------------------------------------------

; ------ data pro datab쟺i

;MaxCPole db        78                       ; max. zobrazen� d굃ka text. pole>10
;DBFEParm db        bit2                     ; parametry
;                                            ;   bit 0: 1=je editace z쟺namu
;                                            ;   bit 1: 1=edit.buffer modifikov쟮
;                                            ;   bit 2: 1=zapnut INSERT
;                                            ;   bit 3: 1=modifikace 눀sel. pole
;                                            ;   bit 4: 1=prohl죷e� TEXT
;                                            ;   bit 5: 1=ozna놽n� z쟺namy/0=v쮍
;                                            ;          1=od kurzoru, 0=na konec
;                                            ;   bit 6: 1=definice nov괿o z쟦lav�
;                                            ;          0=modifik. star괿o z쟦l.
;                                            ;   bit 7:
;
;DBExpPar db        bit0                     ; parametry pro export
;                                            ;   bit 0: 1=od늢ova� 뇿rka
;                                            ;   bit 1: 1=odd늢ova� st쯥dn죏
;                                            ;   bit 2: 1=odd늢ova� tabul쟴or
;                                            ;   bit 3: 1=odd늢ova� r쟭
;                                            ;   bit 4: 1=polo멾y ur놽ny pozic�
;
;DBImpPar db        bit0                     ; parametry pro import
;                                            ;   bit 0: 1=od늢ova� 뇿rka
;                                            ;   bit 1: 1=odd늢ova� st쯥dn죏
;                                            ;   bit 2: 1=odd늢ova� tabul쟴or
;                                            ;   bit 3: 1=odd늢ova� r쟭
;                                            ;   bit 4: 1=polo멾y ur놽ny pozic�

; -----------------------------------------------------------------------------
;        DIS
; -----------------------------------------------------------------------------

; ------ u멼vatelsk� videom줰

UserVMod db        -1                       ; u멼vatelsk� videom줰 (-1 = nen�)

; -----------------------------------------------------------------------------
;        DISK
; -----------------------------------------------------------------------------

;FAktDisk db        0                        ; aktivn� (pracovn�) disk

;FAktForm db        1                        ; aktivn� form쟴 1..

; ------ editace disku

;DZAktMod db        0                        ; aktivn� m줰 editoru disku
;                                            ;   bit 0: 1=je m줰 editace
;                                            ;   bit 1: 1=byla modifikace dat
;                                            ;   bit 2: 0=HEX pole/1=ASCII pole
;                                            ;   bit 3: 0=1.znak HEX/1=2.znak HEX
;                                            ;   bit 4: 1=byl dotaz pro z쟰is

; ------ nulov쟮� disku

NulDPar  db        bit0+bit1+bit2           ; parametry pro nulov쟮� disku
                                            ;    bit 0: 1=nuluj� se adres젵e
                                            ;    bit 1: 1=nuluj� se soubory
                                            ;    bit 2: 1=nuluj� se voln� bloky
NulDBajt db        0                        ; nulovac� bajt disku

; ------ domovsk� programov� adres젵 (dodr멷t po쯠d� polo멷k !)

HomeDirN dw        3                        ; d굃ka domovsk괿o adres젵e
HomeDir  db        'C:\',FileDMax-3 dup(0)  ; cesta k domovsk굆u adres젵i

; ------ konfigura뇆� a datov� adres젵 (dodr멷t po쯠d� polo멷k !)

TempDirN dw        3                        ; d굃ka konfigura뇆죋o adres젵e
TempDir  db        'C:\',FileDMax-3 dup(0)  ; cesta ke konfigura뇆죑u adres젵i

TempDirP db        0                        ; parametry konfigura뇆죋o adres젵e
                                            ;    bit 0: 1=z쟪az z쟰isu do adres젵e

; -----------------------------------------------------------------------------
;        EDI
; -----------------------------------------------------------------------------

;EditBAK  db        25                        ; po놽t z쟫oh souboru BAK

Edit0Vys dw        140*256                  ; relativn� v삩ka okna 1 (0 - 65535)
Edit0Sir dw        131*256                  ; relativn� Æ쯭a okna 1 (0 - 65535)

TextFndN dw        0                        ; d굃ka hledan괿o textu
TextFnd0 db        0                        ; d굃ka textu pro zobrazen� hl젴en�
TextFnd  label     byte
         db        TextFndX dup(0)          ; buffer hledan괿o textu

TextSubN dw        0                        ; d굃ka n쟦radn죋o textu
TextSub0 db        0                        ; d굃ka textu pro zobrazen� hl젴en�
TextSub  label     byte
         db        TextSubX dup(0)          ; buffer n쟦radn죋o textu

EdiHledP db        0                        ; parametry pro hled쟮�
                                            ;    bit 0: 1=hled쟮� zp늯
                                            ;    bit 1: 1=nerozli쮞je velk�/mal�
                                            ;    bit 2: 1=cel� soubor
                                            ;    bit 3: 1=ozna놽n� blok
                                            ;    bit 4: 1=jen cel� slova
                                            ;    bit 5: 1=v쮍chny bez dotazu
                                            ;    bit 6: 1=je n쟦rada textu
                                            ;    bit 7: 1=otazn죏 platn� znak

EdiHldP2 db        0                        ; parametry pro hled쟮� 2
                                            ;    bit 0: 1=hled쟮� bylo zah쟩eno
                                            ;    bit 1: 1=v 쯥t늷ci je otazn죏
                                            ;    bit 2: 1=zad쟮� dat v HEX tvaru
                                            ;    bit 3: 1=hled� se zna뇃a
                                            ;    bit 6: 1=v쮍chny dalÆ bez dotazu
                                            ;    bit 7: 1=nalezen 쯥t늷ec

EditParm db        bit5                     ; parametry pro editor
                                            ;      bit 0: 1=datum a 놹s uchovat
                                            ;      bit 1: 1=hexadec. 커00=text.
                                            ;      bit 2: 1=bin쟲n� 컴�11=autom.
                                            ;      bit 3: 1=prohl죷e�
                                            ;      bit 4: 1=soubor byl vytvo쯥n
                                            ;      bit 5: 1=je zapnut INSERT
                                            ;      bit 6: 1=synchronizace oken
                                            ;      bit 7: 1=p쯥ch.soub.vytvo쯥n

EditPar2 db        0                        ; parametry pro editor 2
                                            ;      bit 0: 1=zobraz kurzor
                                            ;      bit 1: 1=zobraz akt. 찤dek
                                            ;      bit 2: 1=zobraz akt. okno
                                            ;      bit 3: 1=zobraz v쮍chna okna
                                            ;      bit 4: 1=2 okna (0=1 okno)
                                            ;      bit 5: 1=vertik쟫n� (0=horiz.)
                                            ;      bit 6: 1=aktivn� okno 2
                                            ;      bit 7: 1=놹s se zobrazuje

EdiHlKod db        0                        ; konverzn� k줰 souboru pro hled쟮�
                                            ;         0 = implicitn�
                                            ;         1 = ASCII
                                            ;         2 = IBM
                                            ;         3 = Kamenick쁟h
                                            ;         4 = Latin 2
                                            ;         5 = KOI 8
                                            ;         6 = WINDOWS

EdiMdKod db        1                        ; k줰 pro modifikaci bloku
                                            ;    1 = ASCII
                                            ;    2 = IBM
                                            ;    3 = Kamenick쁟h
                                            ;    4 = Latin 2
                                            ;    5 = KOI 8
                                            ;    6 = WINDOWS

OpenEMod db        bit0+bit1+bit2           ; m줰 otev쯥n� editoru pro menu
                                            ;      bit 0: 1=datum a 놹s uchovat
                                            ;      bit 1: 1=hexadec.커00=text.
                                            ;      bit 2: 1=bin쟲n� 켸11=autom.
                                            ;      bit 3: 1=prohl죷e�

OldESwch db        0                        ; inicializa뇆� p쯥p죒a� ze souboru
                                            ;      bit 0: 1=jen zobrazen� (0=edit.)
                                            ;      bit 1: 1=HEX m줰
                                            ;      bit 2: 1=bin쟲n� m줰
                                            ;      bit 3: 1=line쟫
                                            ;      bit 4: 1=tabul쟴or voln�
                                            ;      bit 5: 1=vypnuta optimalizace
                                            ;      bit 6:
                                            ;      bit 7: 1=tabul쟴or b닊n� znak

OldESwc2 db        0                        ; parametry souboru editoru
                                            ;      bit 0:
                                            ;      bit 1:
                                            ;      bit 2: 1=z쟪az z쟰isu
                                            ;      bit 3:
                                            ;      bit 4:
                                            ;      bit 5:
                                            ;      bit 6: 1=sloupcov� blok커0=text.
                                            ;      bit 7: 1=찤dkov� blok 컴� blok

; -----------------------------------------------------------------------------
;        FIL
; -----------------------------------------------------------------------------

EnvSize  dw        0                        ; velikost prost쯥d� (0=standardn�)

SelParam db        bit2                     ; parametry pro v쁞늭 polo멷k
                                            ;   bit 0: 1=ozna뇁t
                                            ;   bit 1: 1=nulovat
                                            ;   bit 2: 1=inverze
                                            ;   bit 4: 1=podadres젵e
                                            ;   bit 5: 1=ozna놽n�
                                            ;   bit 6: 1=uchovat ozna놽n�

; ------ parametry pro konverzi

TabPozic db        8                        ; po놽t pozic na tabul쟴or 1 a� 99

InpKod   db        0                        ; vstupn� k줰 souboru
                                            ;   0 = ASCII
                                            ;   1 = IBM
                                            ;   2 = Kamenick쁟h
                                            ;   3 = Latin 2
                                            ;   4 = KOI 8
                                            ;   5 = Windows

OutKod   db        6                        ; v쁲tupn� k줰 souboru
                                            ;   0 = ASCII
                                            ;   1 = IBM
                                            ;   2 = Kamenick쁟h
                                            ;   3 = Latin 2
                                            ;   4 = KOI 8
                                            ;   5 = Windows
                                            ;   6 = nezm늧늧

FiltrPar db        0                        ; parametry filtru
                                            ;   bit 0: tabul쟴ory na mezery
                                            ;   bit 1: mezery na tabul쟴ory
                                            ;   bit 2: n쟦rada textu
                                            ;   bit 3: mal� p죛mena na velk�
                                            ;   bit 4: velk� p죛mena na mal�
                                            ;   bit 5: 1=zachov쟮 datum a 놹s
                                            ;   bit 7: 1=konverze bez dotazu

; ------ parametry pro tisk

TiskPres dw        0                        ; po놽t p쯥sko놽n쁟h str쟮ek
TiskPoc  dw        1                        ; po뇿te뇆� 눀slo str쟮ky
TiskDelk dw        66                       ; d굃ka str쟮ky s nadpisem (찤dk�)
TiskLeft dw        1                        ; lev� okraj
TiskRght dw        80                       ; prav� okraj

TiskParm db        bit0+bit1                ; parametry pro tisk
                                            ;   bit 0: 1=tisk z쟦lav�
                                            ;   bit 1: 1=놽k쟮� na v쁬늧u pap죚u

TiskOut  dw        bit0                     ; definice v쁲tupn죋o kan쟫u tisku
                                            ;  bit 0: 1=PRN
                                            ;  bit 1: 1=LPT1
                                            ;  bit 2: 1=LPT2
                                            ;  bit 3: 1=LPT3
                                            ;  bit 4: 1=COM1
                                            ;  bit 5: 1=COM2
                                            ;  bit 6: 1=COM3
                                            ;  bit 7: 1=COM4
                                            ;  bit 8: 1=soubor $DOSMAN$.PRN

; ------ nulov쟮� soubor�

NulFBajt db        0                        ; nulovac� bajt soubor�

; ------ start programu

ProgSwc  db        bit1+bit3+bit5+bit6      ; p쯥p죒a놽 voleb
                                            ;   bit 0: 1=BAT m줰
                                            ;   bit 1: 1=Loader
                                            ;   bit 2: 1=rychl� m줰 (perm.)
                                            ;   bit 3: 1=COMMAND.COM
                                            ;   bit 4: 1=d늢en� BAT
                                            ;   bit 5: 1=uschovat v쁞늭
                                            ;   bit 6: 1=COM/EXE/BAT bez pæpon
                                            ;   bit 7: 1=pækaz s $DOSMAN$.BAT

ProgSwc3 db        0                        ;   bit 1: 1=extern� stm죞a�

RusParm2 db        bit1                     ; parametry pro ru쮍n� z menu
                                            ;   bit 0: 1=prov쟡� se nulov쟮� dat
                                            ;   bit 1: 1=prov쟡� se ru쮍n�

CopyPrD2 db        bit2                     ; parametry pro kop죚ov쟮� a p쯥sun
                                            ;  bit 0: 1=aktualizace soubor�
                                            ;  bit 1: 1=zm늧a na kr쟴k� jm굈a
                                            ;  bit 2: 1=uchov쟶at datum a 놹s adres젵�

                                            ;  bit 5: 1=c죐 m� dlouh� jm굈o
                                            ;  bit 6: 1=dlouh� maska se neuplatn�
                                            ;         (nastaveno v InitFCil)
                                            ;  bit 7: 1=c죐ov� jm굈o zru쮍no
                                            ;         (nastaveno v InitFCil)

; ------ porovn쟮� soubor�

CompCfg  db        bit0+bit3                ; konfigurace pro porovn쟶쟮� soubor�
                                            ;   bit 0: automatick� rozli쮍n�
                                            ;   bit 1: textov�
                                            ;   bit 2: bin쟲n�
                                            ;   bit 3: 1=눀slov쟮� TXT 찤dk�
                                            ;   bit 4: 1=zkr쟠en� v쁯is
                                            ;   bit 7: 1=v쁯is do souboru

; -----------------------------------------------------------------------------
;        HLP
; -----------------------------------------------------------------------------

HelpPar  db        bit0                     ; parametry napov늕y
                                            ;   bit 0: 1=zapnuta mal� n쟰ov늕a
                                            ;   bit 1: 1=zobraz� se 12 Fn kl쟶es
                                            ;   bit 2: 1=n쟰ov늕a k menu nen�
                                            ;   bit 3: 1=FN kl쟶esy jako menu
                                            ;   bit 4: 1=otev쯥no menu n쟰ov늕y
                                            ;   bit 5: 1=odkazy p쯫 exportu
                                            ;   bit 6: 1=prob죋� export n쟰ov늕y

; -----------------------------------------------------------------------------
;        KEY
; -----------------------------------------------------------------------------

;MouseChr dw        0                        ; uschovan� znak kurzoru my쮑
MousePoz dw        -1                       ; uschovan� pozice a 찤dek kurzoru

;ParMouse db        0                        ; parametry my쮑
;                                            ;  bit 0: 1=pou멼t� my쮑 zak쟺쟮o
;                                            ;  bit 1: 1=prob늜la instalace
;                                            ;  bit 2: 1=my� je nainstalov쟮a
;                                            ;  bit 3: 1=grafick� m줰 my쮑
;                                            ;  bit 4: 1=p쯥vod sou쯠dnic X 16*
;                                            ;  bit 5: 1=bylo setm늧� prav쁬 rohem

; -----------------------------------------------------------------------------
;        FND
; -----------------------------------------------------------------------------

HledUloP db        bit0                     ; form쟴 pro ulo멷n�
                                            ;   bit 0: 1=seznam FND
                                            ;   bit 1: 1=jm굈a LST
                                            ;   bit 2: 1=DBF
                                            ;   bit 6: 1=aktualizace na눀t쟮�

; -----------------------------------------------------------------------------
;        TRE
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;        UND
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;        WIN
; -----------------------------------------------------------------------------
;�
NWinPthN dw        0                        ; d굃ka cesty k neaktivn죑u oknu
NWinPath label     byte
         db        FileDMax dup(0)          ; cesta k neaktivn죑u oknu

; ------ parametry k n쟶ratu oken (uchovat po쯠d� !)

AWinKOff dw        0                        ; po뇿te뇆� polo멾a aktivn죋o okna
AWinKFil label     byte
         db        FileSumm dup(0)          ; kurzor aktivn죋o okna

NWinKOff dw        0                        ; po뇿te뇆� polo멾a neaktivn죋o okna
NWinKFil label     byte
         db        FileSumm dup(0)          ; kurzor neaktivn죋o okna

; ------ popisova놽 oken (zachovat po쯠d� ParamL/ParamLC ...!)

NumRows0 db        255                      ; u멼vatelsk� v삩ka okna

WindPar  db        bit1                     ; aktu쟫n� parametry oken
                                            ;  bit 0: 1=aktivn� lev� okno
                                            ;  bit 1: 1=okna zapnuta (zobrazena)
                                            ;  bit 2: 1=re멼m zm늧y v삩ky oken
                                            ;  bit 3: 1=re멼m rychlovyhled쟶쟮�
                                            ;  bit 4: 1=volba param. lev괿o okna
                                            ;  bit 5:   (1=byla 1. kl쟶esa Ctrl-K)
                                            ;  bit 6: 1=je re멼m editace soubor�

ParamL   db        bit0 + bit1              ; parametry lev괿o okna
                                            ;   bit 0: okno je zapnuto
                                            ;   bit 1: zobrazen adres젵
                                            ;   bit 2: zobrazen strom
                                            ;   bit 3: zobrazen seznam
                                            ;   bit 4: prot늞Æ okno=prohl죷e�

                                            ;   bit 7: okno je aktivn�

ParamLC  db        0                        ; parametry lev괿o okna - konfig.
                                            ;      bit 0: 1=okno se netæd�
                                            ;      bit 1,2: 0=podle jm굈a
                                            ;               1=podle pæpony
                                            ;               2=podle velikosti
                                            ;               3=podle data a 놹su
                                            ;      bit 3: 1=sestupn� tæd늧�
                                            ;      bit 4: 1=nen� stavov� 찤dek
                                            ;      bit 5,6: 0=Pln� zobrazen�
                                            ;               1=Zkr쟠en� zobrazen�
                                            ;               2=Komentovan� zobrazen�
                                            ;               3=Dlouh� jm굈a
                                            ;      bit 7: 1=zobrazeny atributy

ParamR   db        bit0 + bit1 + bit7       ; parametry prav괿o okna
                                            ;   bit 0: okno je zapnuto
                                            ;   bit 1: zobrazen adres젵
                                            ;   bit 2: zobrazen strom
                                            ;   bit 3: zobrazen seznam
                                            ;   bit 4: prot늞Æ okno=prohl죷e�

                                            ;   bit 7: okno je aktivn�

ParamRC  db        0                        ; parametry prav괿o okna - konfig.
                                            ;      bit 0: 1=okno se netæd�
                                            ;      bit 1,2: 0=podle jm굈a
                                            ;               1=podle pæpony
                                            ;               2=podle velikosti
                                            ;               3=podle data a 놹su
                                            ;      bit 3: 1=sestupn� tæd늧�
                                            ;      bit 4: 1=nen� stavov� 찤dek
                                            ;      bit 5,6: 0=Pln� zobrazen�
                                            ;               1=Zkr쟠en� zobrazen�
                                            ;               2=Komentovan� zobrazen�
                                            ;               3=Dlouh� jm굈a
                                            ;      bit 7: 1=zobrazeny atributy

; -----------------------------------------------------------------------------
;        ZVL
; -----------------------------------------------------------------------------

; ------ ASCII tabulka

AscTbSwc db        1                        ; p쯥p죒a� polohy ASCII tabulky
                                            ;  0 = vlevo
                                            ;  1 = uprost쯥d
                                            ;  2 = vpravo

AscTbSw2 db        0                        ; parametry ASCII tabulky
                                            ;  bit 0: 1=zapnuty barvy

; -----------------------------------------------------------------------------
;        MNU
; -----------------------------------------------------------------------------
;�
ParMenu  db        0                        ; parametry menu
                                            ;  bit 0: 1=je trval� hlavn� menu
                                            ;  bit 1: 1=zobrazeno hlavn� menu
                                            ;  bit 2: 1=zobrazeno n늞ak� menu
                                            ;  bit 3: 1=p쯥chodn� vypnut� oken
                                            ;  bit 4: 1=autom. vno쯥n� do menu
                                            ;  bit 5: 1=autom. vyno쯥n� z menu
                                            ;  bit 6: 1=bylo u멼vatelsk� menu
                                            ;  bit 7: 1=z쟪az opu쮝늧� u멼v.menu

ParMenu2 db        0                        ; parametry menu 2
                                            ;  bit 0: 1=m� se navracet u멼v.menu
                                            ;  bit 1: 1=navr쟴it u멼v. menu

ConfEnd  LABEL     BYTE                     ; konec konfigurace

Data     ENDS

         END
