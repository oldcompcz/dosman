

; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;
;                                L I N E
;
;                        obsluha pækazov괿o 찤dku
;
; =============================================================================
;
;        DispLCom (FAR) - zobrazen� pækazov괿o 찤dku (s kurzorem)
;        DispLKur (FAR) - zobrazen� kurzoru pækazov괿o 찤dku
;        InitLCom (FAR) - inicializace pækazov괿o 찤dku
;        EditLCom (FAR) - editace pækazov괿o 찤dku
;
;        LineCRad (BYTE) - 찤dek na obrazovce k zobrazen� pækazov괿o 찤dku
;        LineCVys (BYTE) - po놽t 찤dk� pækazov괿o 찤dku
;        LineCNum (BYTE) - po놽t znak� v pækazov굆 찤dku
;        LineCMax (BYTE) - maxim쟫n� d굃ka pækazov괿o 찤dku
;        LineCTop (BYTE) - zobrazen� po뇿tek pækazov괿o 찤dku
;        LineCKur (BYTE) - offset kurzoru v pækazov굆 찤dku
;        LineCBuf (BYTE) - buffer pækazov괿o 찤dku
;
;        AktPathN (WORD) - d굃ka cesty aktivn죋o adres젵e
;        AktPath  (BYTE) - aktivn� adres젵
;
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�

INCLUDE  DEF.ASM

CodeLin  SEGMENT   BYTE PUBLIC
         ASSUME    cs:CodeLin,ds:Data

LineCBfN EQU       250                      ; d굃ka bufferu pækazov괿o 찤dku

; *****************************************************************************
;                               MousLin
;                   obsluha pækazov괿o 찤dku myÆ
;            Pozor - m뼇e zevnit� sk쟪at na obsluhu Shift-F2 !!!
; -----------------------------------------------------------------------------
; VSTUP: DS=datov� segment
; V쒾TUP: CY=nen� obsluha
;         ZY=byla obsluha, ale nic se ned늞e
;         NZ=byla obsluha a je start pækazu
; -----------------------------------------------------------------------------
; zni놽n� registry: AX, BX, CX, DX
; *****************************************************************************

MousLin  PROC      FAR

; ------ test, zda je stisk my쮑 v pækazov굆 찤dku

         mov       dl,0                     ; po뇿te뇆� pozice
         mov       dh,ds:[LineCRad]         ; po뇿te뇆� 찤dek
         mov       cl,ds:[Pozic]            ; Æ쯭a okna
         mov       ch,ds:[LineCVys]         ; v삩ka okna
         call      far ptr MouseTst         ; test stisku tla눀tka
         jnc       MousLin2                 ; je stisk tla눀tka my쮑
         jmp       MousLin9                 ; nen� stisk tla눀tka (-> je CY)

; ------ dvoj� stisk - proveden� pækazu

MousLin2:cmp       al,MousXLD               ; lev� tla눀tko 2x ?
         je        MousLin8                 ; je lev� tla눀tko 2x

; ------ test, zda je n늞ak� tla눀tko

         test      al,MousXLH+MousXRH       ; je dr멷n� n늞ak괿o tla눀tka ?
         jz        MousLin9                 ; nen� 몺dn� tla눀tko (-> je ZY)

; ------ vyvol쟮� historie pækaz� (pozor, sk젃e na Shift-F2 !!!)

         mov       al,byte ptr ds:[MousePoz+1] ; 찤dek my쮑
         inc       ax                       ; 1 찤dek rezerva
         cmp       al,ds:[LineCRad]         ; je sm늭em nahoru ?
         jae       MousLin3                 ; nen� vyvol쟮� historie
         add       sp,4                     ; zru쮍n� n쟶ratov� adresy
         jmp       far ptr Progr500         ; obsluha Shift-F2 (historie)

; ------ nastaven� kurzoru na pozici my쮑

MousLin3:cmp       byte ptr ds:[LineCNum],0 ; je n늓o v pækaz. 찤dku ?
         je        MousLn74                 ; nen� nic v pækaz. 찤dku
         mov       al,byte ptr ds:[MousePoz+1] ; 찤dek kurzoru my쮑
         mov       dh,ds:[LineCRad]         ; pækazov� 찤dek
         cmp       al,dh                    ; je nad pækazov쁬 찤dkem ?
         jae       MousLin4                 ; my� je OK
         mov       al,dh                    ; omezen� 찤dku s kurzorem
MousLin4:add       dh,ds:[LineCVys]         ; maxim쟫n� 찤dek
         cmp       al,dh                    ; je pod pækazov쁬 찤dkem ?
         jb        MousLin5                 ; my� je OK
         mov       al,dh                    ; omezen� 찤dku s kurzorem
         dec       ax                       ; oprava na maxim쟫n� 찤dek
MousLin5:sub       al,ds:[LineCRad]         ; 찤dek relativn�
         mul       byte ptr ds:[Pozic]      ; p쯥po놽t na pozici
         add       al,byte ptr ds:[MousePoz] ; p쯫뇍en� pozice my쮑
         adc       ah,0
         sub       al,ds:[LineCPth]         ; ode뇍en� d굃ky cesty
         jnc       MousLin6                 ; nen� podte놽n�
         mov       al,0                     ; omezen� p쯫 podte놽n�
MousLin6:add       al,ds:[LineCTop]         ; p쯫뇍en� po뇿tku
         adc       ah,0
         jnz       MousLin7                 ; je p쯥te놽n�
         cmp       al,ds:[LineCMax]         ; je p쯥te놽n� konce ?
         jbe       MousLn72                 ; nen� p쯥te놽n� konce
MousLin7:mov       al,ds:[LineCMax]         ; omezen� p쯫 p쯥te놽n� kurzoru
MousLn72:cmp       al,ds:[LineCKur]         ; zm늧ila se pozice kurzoru ?
         je        MousLn74                 ; pozice se nezm늧ila
         mov       ds:[LineCKur],al         ; nov� pozice kurzoru
         call      far ptr DispLCom         ; nov� zobrazen� pækaz. 찤dku
MousLn74:call      far ptr DispTime         ; obsluha hodin
         call      far ptr MouseInt         ; obsluha my쮑
         mov       al,ds:[MouseKey]         ; aktu쟫n� stav tla눀tek my쮑
         jmp       short MousLin2           ; nov� obsluha my쮑

; ------ test, zda je n늓o v 찤dku k proveden� (je 2x stisk lev괿o tla눀tka)

MousLin8:cmp       byte ptr ds:[LineCNum],0 ; je n늓o v 찤dku ?
MousLin9:ret

MousLin  ENDP

; *****************************************************************************
;                            DispLCom
;                    zobrazen� pækazov괿o 찤dku
; -----------------------------------------------------------------------------
; VSTUP: DS=datov� segment
; lok쟫n� prom늧n�: SS:[BP-1] (1) ukazatel 찤dku na displeji
;                   SS:[BP-2] (1) 눀ta� 찤dk� k zobrazen�
;                   SS:[BP-3] (1) 눀ta� zbyl쁟h znak� promptu
;                   SS:[BP-4] (1) 눀ta� zbyl쁟h znak� pækazov괿o 찤dku
;                   SS:[BP-6] (2) ukazatel adresy textu
; *****************************************************************************
;�
DispLCom PROC      FAR

         test      byte ptr ds:[WindPar],bit6 ; je re멼m editoru ?
         jz        DispLCm0                 ; nen� re멼m editoru
         ret                                ; jinak konec

; ------ 즧chova registr�

DispLCm0:call      KorLCom                  ; korekce ukazatel� pækaz. 찤dku
         push      ax
         push      cx
         push      dx
         push      si
         push      di
         push      bp
         push      es
         mov       bp,sp

; ------ pæprava po뇍u 찤dk� k zobrazen� (zkr쟠en� p쯫 zobrazen� n쟰ov늕y)

         mov       al,ds:[LineCVys]         ; v삩ka 찤dku
         cmp       al,0                     ; je povoleno zobrazen� ?
         je        DispLC14                 ; nen� povoleno zobrazen� 찤dku
         test      byte ptr ds:[HelpPar],bit0 ; je mal� n쟰ov늕a ?
         jnz       DispLCm2                 ; je mal� n쟰ov늕a - nesni몍je se
         call      far ptr InfoAkt          ; je informa뇆� 찤dek ?
         jnc       DispLCm1                 ; je informa뇆� 찤dek
         test      byte ptr ds:[ParMenu],bit2 ; je n늞ak� menu ?
         jnz       DispLCm1                 ; je n늞ak� menu
         test      byte ptr ds:[WindPar],bit2 ; je re멼m zm늧y v삩ky okna ?
         jz        DispLCm2                 ; nen� ani re멼m zm늧y oken
DispLCm1:dec       al                       ; sn죷en� v삩ky 찤dku, je-li menu
         jnz       DispLCm2                 ; zbyl je쮝� n늞ak� 찤dek
DispLC14:jmp       DispLCmA                 ; nen� co zobrazit

; ------ pæprava lok쟫n죅h prom늧n쁟h (AL=눀ta� 찤dk�)

DispLCm2:sub       sp,6                     ; m죛to pro lok쟫n� prom늧n�
         sub       sp,ds:[ByteRow]          ; buffer pro 찤dek textu
         mov       ah,ds:[LineCRad]         ; 찤dek k zobrazen�
         mov       ss:[bp-2],ax             ; 눀ta� 찤dk� a ukazatel 찤dku
         mov       ah,ds:[LineCPth]         ; d굃ka cesty
         mov       al,ds:[LineCNum]         ; po놽t znak� pækaz. 찤dku
         sub       al,ds:[LineCTop]         ; po놽t zbyl쁟h znak�
         jnc       DispLC23                 ; jsou n늞ak� znaky
         mov       al,0                     ; nezbyl 몺dn� znak
DispLC23:mov       ss:[bp-4],ax             ; 눀ta� zbyl쁟h znak�
         mov       word ptr ss:[bp-6],offset AktPath ; ukazatel adresy cesty
         push      ss
         pop       es                       ; ES <- adresa bufferu

; ------ inicializa뇆� vymaz쟮� bufferu

DispLCm3:mov       di,sp                    ; za뇿tek bufferu
         push      di
         mov       ch,0
         mov       cl,ds:[Pozic]            ; po놽t pozic na 찤dek
         mov       al," "                   ; mazac� mezera
         mov       ah,ds:[LineCCol]         ; barva textu
         cld
         rep       stosw                    ; vymaz쟮� 찤dku
         pop       di

; ------ d굃ka textu cesty (CH=0 !)

         mov       si,ss:[bp-6]             ; ukazatel adresy textu
         mov       al,ss:[bp-3]             ; zbyl� znaky promptu
         mov       dl,ds:[Pozic]            ; po놽t pozic na 찤dek
         cmp       al,dl                    ; je text delÆ ?
         jbe       DispLCm4                 ; text je OK
         mov       al,dl                    ; omezen� d굃ky textu
DispLCm4:sub       ss:[bp-3],al             ; sn죷en� 눀ta놽 zbyl� d굃ky
         sub       dl,al                    ; zbyl� d굃ka 찤dku
         mov       cl,al                    ; po놽t znak� k dek줰ov쟮�
         jcxz      DispLCm6                 ; nezbyl ji� text promptu

; ------ dek줰ov쟮� cesty (CLD !)

         mov       ah,ds:[LinePCol]         ; barva textu cesty
DispLCm5:lodsb                              ; znak k dek줰ov쟮�
         stosw
         loop      DispLCm5                 ; dek줰ov쟮� dalÆho znaku
         mov       ss:[bp-6],si             ; nov� ukazatel textu
         cmp       byte ptr ss:[bp-3],0     ; je ji� konec cesty ?
         jne       DispLCm6                 ; nen� je쮝� konec cesty
         mov       byte ptr es:[di-2],">"   ; ozna놽n� konce promptu
         mov       ah,0
         mov       al,ds:[LineCTop]         ; po뇿tek textu
         add       ax,offset LineCBuf       ; adresa pækazov괿o 찤dku
         mov       ss:[bp-6],ax             ; buffer pækazov괿o 찤dku

; ------ d굃ka textu pækazov괿o 찤dku

DispLCm6:mov       si,ss:[bp-6]             ; ukazatel textu
         mov       al,ss:[bp-4]             ; zbyl� znaky textu
         cmp       al,dl                    ; je text delÆ ?
         jbe       DispLCm7                 ; text je OK
         mov       al,dl                    ; omezen� d굃ky textu
DispLCm7:mov       dl,ss:[bp-4]             ; p뻱odn� d굃ka textu
         sub       ss:[bp-4],al             ; sn죷en� 눀ta놽 zbyl� d굃ky textu
         mov       cl,al                    ; d굃ka textu k dek줰ov쟮�
         jcxz      DispLCm9                 ; nezbyl dalÆ text

; ------ dek줰ov쟮� textu pækazov괿o 찤dku

         mov       ah,ds:[LineCCol]         ; barva textu
         push      di
DispLCm8:lodsb
         stosw
         loop      DispLCm8                 ; dek줰ov쟮� dalÆho znaku
         mov       ss:[bp-6],si             ; nov� ukazatel textu
         pop       si                       ; za뇿tek ukl쟡ac� adresy

; ------ znak p쯥te놽n� za뇿tku 찤dku

         mov       ah,ds:[LineOCol]         ; barva znaku p쯥te놽n�
         mov       al,ds:[LineCTop]         ; za뇿tek textu
         cmp       al,0                     ; je za뇿tek textu ?
         je        DispLC82                 ; je za뇿tek 찤dku
         add       al,dl                    ; fiktivn� d굃ka textu
         cmp       al,ds:[LineCNum]         ; je to prvn� 찤dek textu ?
         jne       DispLC82                 ; nen� to prvn� 찤dek textu
         mov       al,"�"                   ; znak p쯥te놽n�
         mov       es:[si],ax               ; ulo멷n� znaku p쯥te놽n�

; ------ znak p쯥te놽n� konce 찤dku

DispLC82:cmp       byte ptr ss:[bp-2],1     ; je posledn� 찤dek ?
         jne       DispLCm9                 ; nen� posledn� 찤dek
         cmp       byte ptr ss:[bp-4],0     ; zbyly je쮝� n늞ak� znaky ?
         je        DispLCm9                 ; nezbyly 몺dn� znaky
         mov       al,"�"                   ; znak p쯥te놽n�
         mov       es:[di-2],ax             ; znak p쯥te놽n� konce

; ------ zobrazen� 찤dku

DispLCm9:mov       dl,0                     ; po뇿te뇆� pozice
         mov       dh,ss:[bp-1]             ; ukazatel 찤dku na displeji
         mov       cl,ds:[Pozic]            ; d굃ka 찤dku
         mov       si,sp                    ; adresa bufferu
         xor       ax,ax                    ; hladina k zobrazen�
         call      far ptr DispMStr         ; zobrazen� 찤dku

; ------ pæprava pro dalÆ 찤dek

         inc       byte ptr ss:[bp-1]       ; zv삩en� ukazatele 찤dku
         dec       byte ptr ss:[bp-2]       ; 눀ta� 찤dk� k zobrazen�
         jz        DispLCmA                 ; jsou ji� v쮍chny 찤dky
         jmp       DispLCm3                 ; dek줰ov쟮� dalÆho 찤dku

; ------ n쟶rat registr�

DispLCmA:mov       sp,bp
         pop       es
         pop       bp
         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       ax

         call      far ptr DispLKur         ; zobrazen� kurzoru
         ret

DispLCom ENDP

; -----------------------------------------------------------------------------
;                                 KorLCom
;                  oprava ukazatel� pækazov괿o 찤dku
; -----------------------------------------------------------------------------
; VSTUP: DS=datov� segment
; -----------------------------------------------------------------------------

KorLCom  PROC      NEAR

; ------ 즧chova registr�

         push      ax
         push      bx
         push      cx

; ------ celkov� d굃ka 찤dku

         mov       al,ds:[Pozic]            ; po놽t pozic na 찤dek
         mul       byte ptr ds:[LineCVys]   ; celkov� d굃ka 찤dku
         sub       ax,5+1                   ; rezerva
         jc        KorLCom9                 ; nen� nic zobrazeno

; ------ d굃ka aktivn� cesty

         mov       bx,2                     ; d굃ka promptu bez cesty "C:"
         test      byte ptr ds:[LineCPar],bit0 ; je cesta ?
         jnz       KorLCom1                 ; nen� cesta
         mov       bx,ds:[AktPathN]         ; d굃ka aktivn� cesty
         cmp       bx,ax                    ; je d굃ka cesty OK ?
         jb        KorLCom1                 ; d굃ka cesty je OK
         mov       bx,ax                    ; omezen� d굃ky cesty
KorLCom1:inc       bx                       ; zv삩en� d굃ky o znak ">"
         mov       ds:[LineCPth],bl         ; d굃ka cesty
         add       ax,5+1                   ; n쟶rat d굃ky 찤dku

; ------ d굃ka zobraziteln괿o textu 찤dku

         sub       ax,bx                    ; zbytek na 찤dek textu
         mov       ch,0                     ; CH <- 0
         mov       cl,ds:[LineCMax]         ; maxim쟫n� d굃ka 찤dku
         inc       cx                       ; rezerva pro kurzor
         cmp       ax,cx                    ; zb쁵� dost m죛ta ?
         jb        KorLCom2                 ; je dost m죛ta
         xchg      ax,cx                    ; AX <- omezen� d굃ky 찤dku
KorLCom2:mov       ds:[LineCDel],al         ; zobrazen� d굃ka 찤dku

; ------ rezerva po stran쟠h -> CL

         mov       cl,5                     ; rezerva na okraj죅h 5 pozic
         cmp       al,10                    ; zobraz� se m굈� ne� 10 znak� ?
         jae       KorLCom3                 ; zobraz� se dost znak�
         mov       cl,al                    ; po놽t zobrazen쁟h znak�
         shr       cl,1                     ; rezerva na okraj죅h

; ------ ostatn� parametry

KorLCom3:xchg      ax,bx                    ; BL <- zobrazen� d굃ka 찤dku
         mov       bh,ds:[LineCNum]         ; BH <- po놽t znak� v bufferu
         mov       al,ds:[LineCKur]         ; AL <- pozice kurzoru
         cmp       al,bh                    ; je kurzor za koncem ?
         jb        KorLCm32                 ; kurzor nen� za koncem
         mov       bh,al                    ; korekce po뇍u znak� na kurzor
         inc       bh                       ; 1 pozice pro kurzor
KorLCm32:mov       ah,ds:[LineCTop]         ; AH <- po뇿tek 찤dku

; ------ stanoven� maxim쟫n죋o za뇿tku 찤dku

         sub       bh,bl                    ; zobraz� se cel� 찤dek ?
         jbe       KorLCom5                 ; 찤dek se zobraz� cel�

; ------ ohrani놽n� z lev� strany

         sub       al,cl                    ; rezerva na lev굆 okraji
         jbe       KorLCom5                 ; zobraz� se za뇿tek 찤dku
         cmp       al,ah                    ; je p쯥d za뇿tkem 찤dku ?
         jb        KorLCom6                 ; je p쯥d lev쁬 okrajem
         add       al,cl                    ; n쟶rat pozice

; ------ ohrani놽n� z prav� strany

         add       al,cl                    ; rezerva na prav굆 okraji
         sub       al,bl                    ; korekce pro prav� okraj
         jbe       KorLCom4                 ; nen� je쮝� za prav쁬 okrajem
         cmp       al,ah                    ; je za prav쁬 okrajem ?
         jae       KorLCom6                 ; je za prav쁬 okrajem
KorLCom4:mov       al,ah                    ; omezen� na maxim쟫n� po뇿tek
         jmp       short KorLCom6           ; je konec 찤dku

; ------ zobraz� se za뇿tek 찤dku

KorLCom5:mov       al,0                     ; bude za뇿tek 찤dku
         mov       bh,0                     ; maxim쟫n� za뇿tek textu

; ------ kontrola maxim쟫n죋o za뇿tku

KorLCom6:cmp       al,bh                    ; p쯥kro놽n maxim쟫n� za뇿tek ?
         jbe       KorLCom8                 ; nen� p쯥kro놽n maxim쟫n� za뇿tek
         mov       al,bh                    ; omezen� na maxim쟫n� za뇿tek

; ------ nov� po뇿tek pækazov괿o 찤dku

KorLCom8:mov       ds:[LineCTop],al         ; nov� za뇿tek 찤dku

; ------ n쟶rat registr�

KorLCom9:pop       cx
         pop       bx
         pop       ax
         ret

KorLCom  ENDP

; *****************************************************************************
;                                  DispLKur
;           zobrazen� kurzoru pækazov괿o 찤dku (a� po korekci 찤dku !)
; -----------------------------------------------------------------------------
; VSTUP: DS=datov� segment
; *****************************************************************************

DispLKur PROC      FAR

; ------ test, zda je zobrazen� kurzoru povoleno

         test      byte ptr ds:[ParMenu],bit2 ; je n늞ak� menu ?
         jnz       DispLKr1                 ; je n늞ak� menu
         call      far ptr InfoAkt          ; je informa뇆� 찤dek ?
         jnc       DispLKr1                 ; je informa뇆� 찤dek
         test      byte ptr ds:[WindPar],bit2+bit3+bit6 ; editor/qsrc/zm늧a
         jz        DispLKr2                 ; nen� editor/qsrc/zm늧a
DispLKr1:ret                                ; jinak konec

; ------ 즧chova registr�

DispLKr2:push      ax
         push      dx

; ------ nen�-li 몺dn� 찤dek, vypnut� kurzoru

         cmp       byte ptr ds:[LineCVys],0 ; je n늞ak� 찤dek ?
         jne       DispLKr3                 ; je n늞ak� 찤dek
         call      far ptr KurzOff          ; vypnut� kurzoru
         jmp       short DispLKr9

; ------ pozice na 찤dku relativn�

DispLKr3:mov       ah,0                     ; AH <- 0
         mov       al,ds:[LineCKur]         ; offset kurzoru
         sub       al,ds:[LineCTop]         ; offset po뇿tku 찤dku
         add       al,ds:[LineCPth]         ; p쯫뇍en� cesty
         adc       ah,0

; ------ zobrazen� kurzoru

         div       byte ptr ds:[Pozic]      ; v쁯o놽t 찤dku a pozice relativn�
         mov       dh,al                    ; 찤dek relativn�
         mov       dl,ah                    ; pozice
         add       dh,ds:[LineCRad]         ; p쯫뇍en� 찤dku k zobrazen�
         call      far ptr SetKurz          ; nastaven� pozice kurzoru
         call      far ptr SizeLKur         ; nastaven� n죥k괿o kurzoru

; ------ n쟶rat registr�

DispLKr9:pop       dx
         pop       ax
         ret

DispLKur ENDP

; *****************************************************************************
;                             InitLCom
;                  inicializace pækazov괿o 찤dku
; -----------------------------------------------------------------------------
; VSTUP: DS=datov� segment
; *****************************************************************************

InitLCom PROC      FAR

         push      ax
         mov       byte ptr ds:[LineCNum],0 ; zru쮍n� znak� v pækaz. 찤dku
         mov       byte ptr ds:[LineCTop],0 ; offset za뇿tku 찤dku
         mov       byte ptr ds:[LineCKur],0 ; kurzor na za뇿tku 찤dku

         mov       al,127 - 2 - 3 - 2       ; d굃ka - CR/LF - "/C " - rezerva
         cmp       word ptr ds:[EnvSize],0  ; je velikost prost쯥d� ?
         je        InitLCm2                 ; nen� velikost prost쯥d�
         sub       al,9                     ; m죛to pro "/E:32767 "
InitLCm2:mov       ds:[LineCMax],al         ; maxim쟫n� d굃ka pækaz. 찤dku
         mov       byte ptr ds:[SPZMLinM],al ; maxim쟫n� d굃ka pækaz. 찤dku
         pop       ax
         ret

InitLCom ENDP

; *****************************************************************************
;                              EditLCom
;                    editace pækazov괿o 찤dku
;     - u n늟ter쁟h kl쟶es se rozli쮞je, zda je pækazov� 찤dek pr쟺dn�
; -----------------------------------------------------------------------------
; VSTUP: BX=kl쟶esa k editaci
;        DS=datov� segment
; V쒾TUP:BX=0 - kl쟶esa byla obslou멷na
; *****************************************************************************
;�
EditLCom PROC      FAR

; ------ 즧chova registr�

         push      ax
         push      cx
         push      dx
         push      si
         push      di
         push      es

; ------ pæprava registr�

         push      ds
         pop       es                       ; ES <- datov� segment
         mov       al,ds:[LineCKur]         ; kurzor
         mov       ah,0
         mov       si,offset LineCBuf       ; buffer
         add       si,ax                    ; adresa platn괿o znaku

; ------ kontrola, zda je editace 찤dku povolena

         cmp       byte ptr ds:[LineCVys],0 ; je n늞ak� 찤dek ?
         jne       EditLCm1                 ; je n늓o v pækazov굆 찤dku
         jmp       EditLCm9                 ; nen� pækazov� 찤dek

; ------ rozli쮍n� platn괿o znaku

EditLCm1:or        bx,bx                    ; je Ctrl-Break ?
         jz        EditLCm4                 ; je Ctrl-Break nebo neplatn� kl쟶.
         cmp       bh,MousXKod/HI           ; je k줰 my쮑 ?
         je        EditLCm4                 ; my�
         cmp       bx,0300h                 ; je Ctrl-@ ?
         je        EditLCm3                 ; je Ctrl-@
         or        bh,bh                    ; je platn� znak Alt-눀slo ?
         jz        EditLCm3                 ; je platn� znak Alt-눀slo
         cmp       bl," "                   ; je platn� znak ?
         jb        EditLCm4                 ; je ædic� kl쟶esa
         cmp       bx,0e7fh                 ; ^BS
         je        EditLCm4                 ; je ^BS

; ------ je platn� znak - kontrola, zda je voln� m죛to v bufferu

EditLCm3:mov       al,ds:[LineCNum]         ; po놽t znak� v pækazov굆 찤dku
         cmp       al,ds:[LineCMax]         ; je 찤dek pln� ?
         jae       EditLC38                 ; 찤dek je ji� pln�

; ------ kontrola, zda je kurzor za koncem bufferu

         mov       al,ds:[LineCKur]         ; kurzor
         cmp       al,ds:[LineCMax]         ; je kurzor za koncem ?
         jae       EditLC38                 ; kurzor je za koncem

; ------ dopln늧� mezer po kurzor

         sub       al,ds:[LineCNum]         ; po놽t chyb늞죅죅h znak�
         jbe       EditLC34                 ; nen� za koncem textu
         mov       ah,0
         mov       cx,ax                    ; CX <- po놽t mezer k dopln늧�
         mov       di,offset LineCBuf       ; buffer
         mov       al,ds:[LineCNum]         ; po놽t znak� v bufferu
         add       di,ax                    ; adresa konce textu
         mov       al," "                   ; mazac� znak mezery
         cld
         add       ds:[LineCNum],cl         ; zv삩en� po뇍u znak� v bufferu
         rep       stosb                    ; dopln늧� mezer

; ------ vlo멷n� znaku do bufferu

EditLC34:mov       cx,LineCBfN-1            ; velikost bufferu - 1
         sub       cl,ds:[LineCKur]         ; zbyl� po놽t znak� v bufferu
         mov       di,offset LineCBuf+LineCBfN-1 ; posledn� znak bufferu
         mov       si,offset LineCBuf+LineCBfN-2 ; p쯥dposledn� znak bufferu
         std                                ; sm늭 dol�
         rep       movsb                    ; odsunut� zbytku textu
         mov       byte ptr ds:[di],bl      ; ulo멷n� znaku do bufferu
         inc       byte ptr ds:[LineCNum]   ; zv삩en� po뇍u znak� v bufferu
         inc       byte ptr ds:[LineCKur]   ; zv삩en� pozice kurzoru
EditLC38:jmp       short EditLCm8

; ------ kontrola, zda je pækazov� 찤dek pr쟺dn�

EditLCm4:cmp       byte ptr ds:[LineCNum],0 ; je n늓o v pækazov굆 찤dku ?
         je        EditLCm9                 ; pækazov� 찤dek je pr쟺dn�

; ------ obsluha ædic죅h kl쟶es (AL=kurzor, SI=adresa v bufferu)

         mov       ah,ds:[LineCNum]         ; po놽t znak� v bufferu
         mov       ch,ds:[LineCMax]         ; maxim쟫n� d굃ka 찤dku
         call      EditLCm5                 ; skok na obsluhu kl쟶esy
         mov       ds:[LineCKur],al         ; nov� pozice kurzoru
         jmp       short EditLCm8           ; nov� zobrazen� 찤dku

EditLCm5:call      far ptr JumpBX

         dw        4b00h,EdLLft             ; vlevo - posun kurzoru vlevo
         dw        1f13h,EdLLft             ; ^S - vlevo
         dw        4d00h,EdLRgh             ; vpravo - posun kurzoru vpravo
         dw        2004h,EdLRgh             ; ^D - vpravo
         dw        0e08h,EdLBs              ; BS - maz쟮� znaku vlevo
         dw        2308h,EdLBs              ; ^H - maz쟮� znaku vlevo
         dw        5300h,EdLDel             ; DEL - maz쟮� znaku za kurzorem
         dw        2207h,EdLDel             ; ^G - maz쟮� znaku za kurzorem
         dw        4700h,EdLHome            ; HOME - kurzor na za뇿tek 찤dku
         dw        4f00h,EdLEnd             ; END - kurzor na konec 찤dku
         dw        011bh,EdLClr             ; ESC - zru쮍n� 찤dku
         dw        1519h,EdLClr             ; ^Y - zru쮍n� 찤dku
         dw        7300h,EdLCLf             ; ^vlevo - slovo vlevo
         dw        1e01h,EdLCLf             ; ^A - slovo vlevo
         dw        7400h,EdLCRg             ; ^vpravo - slovo vpravo
         dw        2106h,EdLCRg             ; ^F - slovo vpravo
         dw        0e7fh,EdLCBS             ; ^BS - vymaz쟮� slova p쯥d kurzorem
         dw        9300h,EdLCDel            ; ^DEL - vymaz쟮� slova za kurzorem
         dw        1414h,EdLCDel            ; ^T - vymaz쟮� slova za kurzorem
         dw        0c1fh,EdLCPom            ; ^- - z쟭늧a 2 znak�

         dw        0,EditLCm6               ; kl쟶esa nenalezena

EditLCm6:pop       ax                       ; zru쮍n� n쟶ratov� adresy
         jmp       short EditLCm9

; ------ nov� zobrazen� po obsluze kl쟶esy

EditLCm8:xor       bx,bx                    ; pæznak obsluhy kl쟶esy
         call      far ptr DispLCom         ; nov� zobrazen� 찤dku

; ------ n쟶rat registr�

EditLCm9:pop       es
         pop       di
         pop       si
         pop       dx
         pop       cx
         pop       ax
         ret

EditLCom ENDP

; -----------------------------------------------------------------------------
;        posun kurzoru o znak vlevo
; -----------------------------------------------------------------------------

EdLLft   PROC      NEAR

         cmp       al,0                     ; je ji� za뇿tek 찤dku ?
         je        EdLLft9                  ; je ji� za뇿tek 찤dku
         dec       ax                       ; sn죷en� pozice kurzoru
EdLLft9: ret

EdLLft   ENDP

; -----------------------------------------------------------------------------
;        posun kurzoru o znak vpravo
; -----------------------------------------------------------------------------

EdLRgh   PROC      NEAR

         cmp       al,ch                    ; je ji� konec 찤dku ?
         jae       EdLRgh9                  ; je ji� konec 찤dku
         inc       ax                       ; zv삩en� pozice kurzoru
EdLRgh9: ret

EdLRgh   ENDP

; -----------------------------------------------------------------------------
;        maz쟮� znaku p쯥d kurzorem
; -----------------------------------------------------------------------------

EdLBs    PROC      NEAR

         cmp       al,0                     ; je ji� za뇿tek 찤dku ?
         je        EdLDel9                  ; je ji� za뇿tek 찤dku
         dec       ax                       ; sn죷en� pozice kurzoru
         dec       si                       ; sn죷en� adresy kurzoru
                                          ;* pokra뇎je maz쟮� znaku nad kurz. !
EdLBs    ENDP

; -----------------------------------------------------------------------------
;        maz쟮� znaku za kurzorem (mus� n쟳ledovat za EdLBs !)
; -----------------------------------------------------------------------------

EdLDel   PROC      NEAR

         cmp       al,ah                    ; je kurzor na konci 찤dku ?
         jae       EdLDel9                  ; kurzor na konci - nen� co mazat
         call      DelChar                  ; zru쮍n� znaku na pozici AL
EdLDel9: ret

EdLDel   ENDP

; -----------------------------------------------------------------------------
;        posun kurzoru na za뇿tek 찤dku
; -----------------------------------------------------------------------------

EdLHome  PROC      NEAR

         mov       al,0                     ; posun kurzoru na za뇿tek 찤dku
         ret

EdLHome  ENDP

; -----------------------------------------------------------------------------
;        posun kurzoru na konec 찤dku
; -----------------------------------------------------------------------------

EdLEnd   PROC      NEAR

         mov       al,ah                    ; po놽t znak� v bufferu
         ret

EdLEnd   ENDP

; -----------------------------------------------------------------------------
;        vymaz쟮� 찤dku
; -----------------------------------------------------------------------------

EdLClr   PROC      NEAR

         call      far ptr InitLCom         ; inicializace pækaz. 찤dku
         xor       ax,ax                    ; AL <- 0 nov� pozice kurzoru
         ret

EdLClr   ENDP

; -----------------------------------------------------------------------------
;        slovo vlevo
; -----------------------------------------------------------------------------

EdLCLf   PROC      NEAR

; ------ sn죷en� pozice kurzoru o znak vlevo

         cmp       al,0                     ; je ji� po뇿tek 찤dku ?
         je        EdLCLf9                  ; je ji� po뇿tek 찤dku
         cmp       al,ah                    ; je za koncem textu ?
         ja        EdLEnd                   ; je za koncem textu
EdLCLf2: dec       si                       ; sn죷en� adresy v bufferu
         dec       al                       ; sn죷en� pozice kurzoru
         jz        EdLCLf9                  ; je ji� za뇿tek 찤dku

; ------ test, zda je ji� za뇿tek slova

         push      ax
         mov       ax,ds:[si-1]             ; p쯥dch쟺ej죅� znak a kurzor
         call      far ptr TestWrd          ; test, zda je za뇿tek slova
         pop       ax
         jc        EdLCLf2                  ; nen� za뇿tek slova - dalÆ znak

EdLCLf9: ret

EdLCLf   ENDP

; -----------------------------------------------------------------------------
;        slovo vpravo
; -----------------------------------------------------------------------------

EdLCRg   PROC      NEAR

; ------ zv삩en� pozice kurzoru o znak vpravo

         cmp       al,ah                    ; je ji� konec textu ?
         jae       EdLEnd                   ; je ji� konec textu
EdLCRg2: inc       si                       ; sn죷en� adresy v bufferu
         inc       ax                       ; zv삩en� pozice kurzoru
         cmp       al,ah                    ; je ji� konec textu ?
         jae       EdLCRg9                  ; je ji� konec textu

; ------ test, zda je ji� za뇿tek slova

         push      ax
         mov       ax,ds:[si-1]             ; p쯥dch쟺ej죅� znak a kurzor
         call      far ptr TestWrd          ; test, zda je za뇿tek slova
         pop       ax
         jc        EdLCRg2                  ; nen� za뇿tek slova - dalÆ znak

EdLCRg9: ret

EdLCRg   ENDP

; -----------------------------------------------------------------------------
;        vymaz쟮� slova p쯥d kurzorem
; -----------------------------------------------------------------------------

EdLCBS   PROC      NEAR

; ------ vymaz쟮� p쯥de쮔괿o znaku

EdLCBS1: cmp       al,0                     ; je ji� po뇿tek 찤dku ?
         je        EdLCBS9                  ; je ji� po뇿tek 찤dku
EdLCBS2: dec       si                       ; sn죷en� adresy v bufferu
         dec       ax                       ; sn죷en� pozice kurzoru
         cmp       al,ah                    ; je za koncem textu ?
         jae       EdLCBS1                  ; je za koncem textu
         mov       cl,ds:[si]               ; 즧chova ru쮍n괿o znaku
         call      DelChar                  ; zru쮍n� znaku na pozici kurzoru
         dec       ah                       ; sn죷en� d굃ky textu
         cmp       al,0                     ; je ji� po뇿tek 찤dku ?
         je        EdLCBS9                  ; je ji� po뇿tek 찤dku

; ------ test, zda je ji� za뇿tek slova

         push      ax
         mov       al,ds:[si-1]             ; p쯥dch쟺ej죅� znak
         mov       ah,cl                    ; znak na pozici kurzoru
         call      far ptr TestWrd          ; test, zda je za뇿tek slova
         pop       ax
         jc        EdLCBS2                  ; nen� za뇿tek slova - dalÆ znak

EdLCBS9: ret

EdLCBS   ENDP

; -----------------------------------------------------------------------------
;        vymaz쟮� slova za kurzorem
; -----------------------------------------------------------------------------

EdLCDel   PROC      NEAR

; ------ vymaz쟮� n쟳leduj죅죋o znaku

         cmp       al,ah                    ; je ji� konec 찤dku ?
         jae       EdLCDel9                 ; je ji� konec 찤dku
EdLCDel2:mov       cl,ds:[si]               ; 즧chova ru쮍n괿o znaku
         call      DelChar                  ; zru쮍n� znaku na pozici kurzoru
         dec       ah                       ; sn죷en� d굃ky textu
         cmp       al,ah                    ; je ji� konec textu ?
         jae       EdLCDel9                 ; je ji� konec textu

; ------ test, zda je ji� za뇿tek slova

         push      ax
         mov       al,cl                    ; ru쮍n� znak
         mov       ah,ds:[si]               ; n쟳leduj죅� znak
         call      far ptr TestWrd          ; test, zda je za뇿tek slova
         pop       ax
         jc        EdLCDel2                 ; nen� za뇿tek slova - dalÆ znak

EdLCDel9:ret

EdLCDel   ENDP

; -----------------------------------------------------------------------------
;        z쟭늧a dvou znak� za kurzorem
; -----------------------------------------------------------------------------

EdLCPom  PROC      NEAR

         cmp       ah,0                     ; je n늞ak� text ?
         je        EdLCPom9                 ; nen� 몺dn� text
         dec       ah                       ; 1 znak rezerva
         cmp       al,ah                    ; zb쁵aj� 2 znaky ?
         ja        EdLCPom9                 ; kurzor je za koncem 찤dku
         jb        EdLCPom4                 ; nen� posledn� znak

; ------ kurzor na posledn죑 znaku - vlo멷n� mezery

         cmp       al,ch                    ; je maxim쟫n� konec ?
         jae       EdLCPom9                 ; je ji� maxim쟫n� konec
         mov       byte ptr ds:[si+1]," "   ; dalÆ znak bude mezera
         inc       byte ptr ds:[LineCNum]   ; zv삩en� po뇍u znak� v bufferu

; ------ z쟭늧a 2 znak�

EdLCPom4:mov       ah,ds:[si]
         xchg      ah,ds:[si+1]
         mov       ds:[si],ah

EdLCPom9:ret

EdLCPom  ENDP

; -----------------------------------------------------------------------------
;        maz쟮� znaku na pozici AL, adresa SI
; -----------------------------------------------------------------------------

DelChar  PROC      NEAR

; ------ 즧chova registr�

         push      cx
         push      si
         push      di

; ------ maz쟮� znaku v bufferu

         mov       di,si                    ; adresa kurzoru
         inc       si                       ; adresa kurzoru + 1
         mov       ch,0
         mov       cl,ds:[LineCNum]         ; po놽t znak� textu
         sub       cl,al                    ; zbytek textu
         jbe       DelChar4                 ; nen� nic ke zru쮍n�
         cld                                ; sm늭 nahoru
         rep       movsb                    ; pæsun zbytku textu a koncov� " "
         dec       byte ptr ds:[LineCNum]   ; sn죷en� po뇍u znak� v bufferu

; ------ n쟶rat registr�

DelChar4:pop       di
         pop       si
         pop       cx
         ret

DelChar  ENDP

CodeLin  ENDS

; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;
;                                 Data
;
; 같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;�
Data     SEGMENT

;LinePCol db        0fh                      ; barva textu promptu
;LineCCol db        7                        ; barva textu pækaz. 찤dku
;LineOCol db        0eh                      ; barva znaku p쯥te놽n�

; ------ definice zobrazen� 찤dku

LineCRad db        22                       ; 찤dek k zobrazen�
LineCPth db        76                       ; d굃ka cesty k zobrazen�
LineCDel db        80                       ; zobrazen� d굃ka pækaz. 찤dku
LineCVys db        1                        ; v삩ka - po놽t 찤dk� (0 a� 2)

; ------ definice obsahu 찤dku

LineCNum db        0                        ; po놽t znak� v pækaz. 찤dku
LineCMax db        120                      ; maxim쟫n� d굃ka pækaz. 찤dku
                                            ;  (je bu� 120 nebo 111)
LineCTop db        0                        ; offset za뇿tku zobrazen괿o textu
LineCKur db        0                        ; pozice kurzoru v textu

LineCPar db        0                        ; parametry 찤dku
                                            ;    bit 0: 1=nen� adres젵ov� cesta

LineCBuf label     byte
         db        LineCBfN dup(" ")        ; buffer pækazov괿o 찤dku (+rezerva)
                                            ; (dek줰uje se sem nap�. pækaz pro
                                            ;  konfiguraci + pln� cesta jako parametr

Data     ENDS

         END
