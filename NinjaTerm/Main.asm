SCREEN = $1000
COLOR = $9400
CCHAR = $1800
CCHARSIZE = $08
FROM = $fb
TO = $fd
CURKEY = $C5
CUREN = $CC
CURROW = $D6
PRESSED = $FF
RSSTAT = $663
MODE = $291
BITNUM = $298
ridbe = $029b
ridbs = $029c

KEY_MENU   = 133
KEY_TERM   = 134
KEY_HANGUP = 138
KEY_UPPER  = 140
KEY_LOWER  = 136

KEY_BAUD   = 133
KEY_ADDR   = 137
KEY_SAVE   = 135
KEY_DEFAULT= 139

VIC_VICCR2 = $9002
VIC_VICCR3 = $9003
VIC_VICCR5 = $9005
VIC_VICCRF = $900F

RSNXTBYT   = $EFEE

CHROUT    = $FFD2
CHKIN      = $FFC6
CHKOUT     = $FFC9
CHRIN      = $FFCF
CLALL      = $FFE7
CLOSE      = $FFC3
CLRCHN     = $FFCC
GETIN      = $FFE4
READST     = $FFB7
SETLFS     = $FFBA
SETNAM     = $FFBD
OPEN       = $FFC0
PLOT       = $FFF0

;;----------------------------------------------------
; 10 SYS8192

*=$1201

        BYTE    $0B, $12, $0A, $00, $9E, $38, $31, $39, $32, $00, $00, $00

;;----------------------------------------------------
SIZEH   byte $00
SIZEL   byte $00
;PRESSED byte $00
ECHO    byte $00

BAUD_RATE
        byte 1

USERPORT_SETUP_STRING
        byte %00001000 ;; 8 bit, 1 stop, 2400 Baud
        byte %00000000 ;; No parity, full duplex, 3-line
        byte $00
        
_B2400  byte %00001010
_B1200  byte %00001000
_B300   byte %00000110

_T2400  text '2400'
_T1200  text '1200'
_T300   text '300 '


;;----------------------------------------------------
*=$2000
        jsr CLALL

        ; BLACK/BLACK Background
        lda #$08
        sta VIC_VICCRF

        jsr Setup_Charset_Lower

        lda VIC_VICCR2
        and #%01111111
        sta VIC_VICCR2

        lda VIC_VICCR5
        and #%00000000
        ora #%11001110 
        sta VIC_VICCR5

        lda #$00
        sta CUREN

        lda #$F0
        sta MODE

        jsr Setup_Screen
        jsr Setup_Keyboard
        jsr Setup_Userport

MAIN_ST jsr Show_Term_Screen

MAIN_A

        ldx #1
        JSR CHKIN
        JSR GETIN
        BNE KEY_IN

        ldx #2
        JSR CHKIN
        JSR rshavedata
        BEQ MAIN_A
        JSR CHRIN
        jmp RS232_IN

KEY_IN
        sta PRESSED

        cmp #KEY_UPPER
        beq MAIN_T1

        cmp #KEY_LOWER
        bne MAIN_K1
        jsr Setup_Charset_Lower
        jmp MAIN_A

MAIN_T1 jsr Setup_Charset_Upper
        jmp MAIN_A

MAIN_K1 cmp #KEY_TERM
        bne MAIN_K2
        jmp MAIN_ST

MAIN_K2 cmp #KEY_MENU
        bne MAIN_K3
        jsr Options
        jmp MAIN_ST

MAIN_K3 cmp #KEY_HANGUP
        bne MAIN_K4
        jsr hangup
        jmp MAIN_A

MAIN_K4

MAIN_KOUT
        ldx #10
        jsr CHKOUT

        lda PRESSED
        jsr CHROUT
        jmp MAIN_A

RS232_IN

        pha

        ldx #3
        jsr CHKOUT

        pla
        jsr CHROUT 
        
        jmp MAIN_A


MAIN_KDONE
        lda #2
        JSR CLOSE
        JSR CLRCHN
        rts

;;----------------------------------------------------
hangup
        ldx #10
        jsr CHKOUT
        lda #30
        jsr WAIT
        lda #'+'
        jsr CHROUT
        lda #1
        jsr WAIT
        lda #'+'
        jsr CHROUT
        lda #1
        jsr WAIT
        lda #'+'
        jsr CHROUT
        lda #120
        jsr WAIT
        lda #65
        jsr CHROUT
        lda #6
        jsr WAIT
        lda #84
        jsr CHROUT
        lda #6
        jsr WAIT
        lda #72
        jsr CHROUT
        lda #6
        jsr WAIT
        lda #13
        jsr CHROUT
        lda #60
        jsr WAIT
        rts

;;----------------------------------------------------
WAIT
counter = $fb ; a zeropage address to be used as a counter
        sta delay

        lda #$00    ; reset
        sta counter ; counter

        sei       ; enable interrupts

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

loop1   lda $9004  ; wait for vertical retrace
        and #%1000000
        cmp #%1000000 ; until it reaches 256th raster line
        bne loop1 ; which is out of the inner screen area

        inc counter ; increase frame counter
        lda counter ; check if counter
        cmp delay   ; reached delay
        bne out     ; if not, pass the color changing routine

        lda #$00    ; reset
        sta counter ; counter

        cli
        rts

out     lda $9004 ; make sure we reached
        and #%1000000
        cmp #%0000000 ; the next raster line so next time we
        bne out ; should catch the same line next frame

        jmp loop1 ; jump to main loop

delay   byte 60 ; 1 second NTSC

;;----------------------------------------------------
Options
        lda #3
        jsr CHKOUT
        jsr Show_Options_Screen

        ldx #2
        ldy #15
        jsr PLOT

        lda BAUD_RATE
        cmp #$00
        bne OP_B1       ; 300
        lda _B300
        sta USERPORT_SETUP_STRING
        jsr Setup_Userport
        lda _T300
        jsr CHROUT
        lda _T300 + 1
        jsr CHROUT
        lda _T300 + 2
        jsr CHROUT
        lda _T300 + 3
        jsr CHROUT        
        jmp OPT_A

OP_B1   cmp #$01
        bne OP_B2       ; 1200
        lda _B1200
        sta USERPORT_SETUP_STRING
        jsr Setup_Userport
        lda _T1200
        jsr CHROUT
        lda _T1200 + 1
        jsr CHROUT
        lda _T1200 + 2
        jsr CHROUT
        lda _T1200 + 3
        jsr CHROUT
        jmp OPT_A

OP_B2   cmp #$02
        bne OP_BU
        lda _B2400
        sta USERPORT_SETUP_STRING
        jsr Setup_Userport
        lda _T2400
        jsr CHROUT
        lda _T2400 + 1
        jsr CHROUT
        lda _T2400 + 2
        jsr CHROUT
        lda _T2400 + 3
        jsr CHROUT
        jmp OPT_A

OP_BU   lda #$20
        jsr CHROUT
        jsr CHROUT
        jsr CHROUT
        jsr CHROUT

OPT_A   jsr GETIN
        beq OPT_A

        sta PRESSED

        cmp #KEY_BAUD
        bne OPT_AA
        inc BAUD_RATE
        lda BAUD_RATE
        cmp #3
        bne OPT_AA
        lda #$00
        sta BAUD_RATE

OPT_AA  lda PRESSED
        cmp #KEY_TERM
        bne OPT_AB
        rts

OPT_AB  lda PRESSED
        cmp #KEY_HANGUP
        bne OPT_AC
        jsr hangup
        rts

OPT_AC  lda PRESSED
        cmp #KEY_ADDR
        bne OPT_AD
        ; JSR ADDRESSES
        
OPT_AD  lda PRESSED
        cmp #KEY_DEFAULT
        bne OPT_AE
        lda #1
        sta BAUD_RATE
        jmp Options
        
OPT_AE
OPT_N   jmp Options
        
OPT_B   
        rts

;;----------------------------------------------------
; A = 0 when no data
; A = 1 when data
rshavedata
        lda #0
        ldy ridbs
        cpy ridbe       ; buffer empty?
        beq rsempty     ; no
        lda #1

rsempty
        rts 

;;----------------------------------------------------
Setup_Keyboard
        lda #$00
        ldx #0
        ldy #0
        jsr SETNAM

        LDA #1
        LDX #0
        LDY #0
        JSR SETLFS

        jsr OPEN

        rts

;;----------------------------------------------------
Setup_Screen
        lda #$00
        ldx #0
        ldy #0
        jsr SETNAM

        LDA #3
        LDX #3
        LDY #0
        JSR SETLFS

        jsr OPEN

        rts

;;----------------------------------------------------
Setup_Userport
        lda #2
        jsr CLOSE
        lda #10
        jsr CLOSE

        lda #$01
        ldx #<USERPORT_SETUP_STRING
        ldy #>USERPORT_SETUP_STRING
        jsr SETNAM

        LDA #2
        LDX #2
        LDY #0
        JSR SETLFS

        jsr OPEN

        jsr READST

        LDA #10
        LDX #2
        LDY #0
        JSR SETLFS

        jsr OPEN

        jsr READST

        rts


;;;----------------------------------------------------
Setup_Charset_Lower
        lda #<CHARS_LOWER
        sta FROM
        lda #>CHARS_LOWER
        sta FROM + 1

        lda #<CCHAR
        sta TO
        lda #>CCHAR
        sta TO + 1

        lda #CCHARSIZE
        sta SIZEH
        lda #$00
        sta SIZEL

        jsr MOVEDOWN
        
        rts

;;----------------------------------------------------
Setup_Charset_Upper
        lda #<CHARS_UPPER
        sta FROM
        lda #>CHARS_UPPER
        sta FROM + 1

        lda #<CCHAR
        sta TO
        lda #>CCHAR
        sta TO + 1

        lda #CCHARSIZE
        sta SIZEH
        lda #$00
        sta SIZEL

        jsr MOVEDOWN
        
        rts

;;----------------------------------------------------
Show_Term_Screen
        ; Screen 
        lda #<Term_window_screen_data
        sta FROM
        lda #>Term_window_screen_data
        sta FROM + 1

        lda #<SCREEN
        sta TO
        lda #>SCREEN
        sta TO + 1

        lda #$02
        sta SIZEH
        lda #$00
        sta SIZEL

        jsr MOVEDOWN

        ; Color
        LDA #<Term_window_colour_data
        sta FROM
        LDA #>Term_window_colour_data
        sta FROM +1

        lda #<COLOR
        sta TO
        lda #>COLOR
        sta TO + 1

        jsr MOVEDOWN

        ldy #$00
        ldx #$03
        clc
        jsr PLOT
        
        rts

;;----------------------------------------------------
Show_Options_Screen
        ; Screen 
        lda #<Options_screen_data
        sta FROM
        lda #>Options_screen_data
        sta FROM + 1

        lda #<SCREEN
        sta TO
        lda #>SCREEN
        sta TO + 1

        lda #$02
        sta SIZEH
        lda #$00
        sta SIZEL

        jsr MOVEDOWN

        ; Color
        LDA #<Options_colour_data
        sta FROM
        LDA #>Options_colour_data
        sta FROM +1

        lda #<COLOR
        sta TO
        lda #>COLOR
        sta TO + 1

        jsr MOVEDOWN

        ldy #$00
        ldx #$03
        clc
        jsr PLOT
        
        rts


;;----------------------------------------------------
; Move memory down
;
; FROM = source start address
;   TO = destination start address
; SIZE = number of bytes to move
;
MOVEDOWN
         LDY #0
         LDX SIZEH
         BEQ MD2
MD1     
         lda (FROM),Y
         STA (TO),Y
         INY
         BNE MD1
         INC FROM+1
         INC TO+1
         DEX
         BNE MD1

MD2     
         LDX SIZEL
         BEQ MD4

MD3     
         LDA (FROM),Y
         STA (TO),Y
         INY
         DEX
         BNE MD3

MD4     
        RTS




;;----------------------------------------------------
*=$4000

; Charset
CHARS_UPPER
        byte    $3c,$66,$6e,$6e,$60,$62,$3c,$00
        byte    $18,$3c,$66,$7e,$66,$66,$66,$00
        byte    $7c,$66,$66,$7c,$66,$66,$7c,$00
        byte    $3c,$66,$60,$60,$60,$66,$3c,$00
        byte    $78,$6c,$66,$66,$66,$6c,$78,$00
        byte    $7e,$60,$60,$78,$60,$60,$7e,$00
        byte    $7e,$60,$60,$78,$60,$60,$60,$00
        byte    $3c,$66,$60,$6e,$66,$66,$3c,$00
        byte    $66,$66,$66,$7e,$66,$66,$66,$00
        byte    $3c,$18,$18,$18,$18,$18,$3c,$00
        byte    $1e,$0c,$0c,$0c,$0c,$6c,$38,$00
        byte    $66,$6c,$78,$70,$78,$6c,$66,$00
        byte    $60,$60,$60,$60,$60,$60,$7e,$00
        byte    $63,$77,$7f,$6b,$63,$63,$63,$00
        byte    $66,$76,$7e,$7e,$6e,$66,$66,$00
        byte    $3c,$66,$66,$66,$66,$66,$3c,$00
        byte    $7c,$66,$66,$7c,$60,$60,$60,$00
        byte    $3c,$66,$66,$66,$66,$3c,$0e,$00
        byte    $7c,$66,$66,$7c,$78,$6c,$66,$00
        byte    $3c,$66,$60,$3c,$06,$66,$3c,$00
        byte    $7e,$18,$18,$18,$18,$18,$18,$00
        byte    $66,$66,$66,$66,$66,$66,$3c,$00
        byte    $66,$66,$66,$66,$66,$3c,$18,$00
        byte    $63,$63,$63,$6b,$7f,$77,$63,$00
        byte    $66,$66,$3c,$18,$3c,$66,$66,$00
        byte    $66,$66,$66,$3c,$18,$18,$18,$00
        byte    $7e,$06,$0c,$18,$30,$60,$7e,$00
        byte    $3c,$30,$30,$30,$30,$30,$3c,$00
        byte    $0c,$12,$30,$7c,$30,$62,$fc,$00
        byte    $3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
        byte    $00,$18,$3c,$7e,$18,$18,$18,$18
        byte    $00,$10,$30,$7f,$7f,$30,$10,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00
        byte    $18,$18,$18,$18,$00,$00,$18,$00
        byte    $66,$66,$66,$00,$00,$00,$00,$00
        byte    $66,$66,$ff,$66,$ff,$66,$66,$00
        byte    $18,$3e,$60,$3c,$06,$7c,$18,$00
        byte    $62,$66,$0c,$18,$30,$66,$46,$00
        byte    $3c,$66,$3c,$38,$67,$66,$3f,$00
        byte    $06,$0c,$18,$00,$00,$00,$00,$00
        byte    $0c,$18,$30,$30,$30,$18,$0c,$00
        byte    $30,$18,$0c,$0c,$0c,$18,$30,$00
        byte    $00,$66,$3c,$ff,$3c,$66,$00,$00
        byte    $00,$18,$18,$7e,$18,$18,$00,$00
        byte    $00,$00,$00,$00,$00,$18,$18,$30
        byte    $00,$00,$00,$7e,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$18,$18,$00
        byte    $00,$03,$06,$0c,$18,$30,$60,$00
        byte    $3c,$66,$6e,$76,$66,$66,$3c,$00
        byte    $18,$18,$38,$18,$18,$18,$7e,$00
        byte    $3c,$66,$06,$0c,$30,$60,$7e,$00
        byte    $3c,$66,$06,$1c,$06,$66,$3c,$00
        byte    $06,$0e,$1e,$66,$7f,$06,$06,$00
        byte    $7e,$60,$7c,$06,$06,$66,$3c,$00
        byte    $3c,$66,$60,$7c,$66,$66,$3c,$00
        byte    $7e,$66,$0c,$18,$18,$18,$18,$00
        byte    $3c,$66,$66,$3c,$66,$66,$3c,$00
        byte    $3c,$66,$66,$3e,$06,$66,$3c,$00
        byte    $00,$00,$18,$00,$00,$18,$00,$00
        byte    $00,$00,$18,$00,$00,$18,$18,$30
        byte    $0e,$18,$30,$60,$30,$18,$0e,$00
        byte    $00,$00,$7e,$00,$7e,$00,$00,$00
        byte    $70,$18,$0c,$06,$0c,$18,$70,$00
        byte    $3c,$66,$06,$0c,$18,$00,$18,$00
        byte    $00,$00,$00,$ff,$ff,$00,$00,$00
        byte    $08,$1c,$3e,$7f,$7f,$1c,$3e,$00
        byte    $18,$18,$18,$18,$18,$18,$18,$18
        byte    $00,$00,$00,$ff,$ff,$00,$00,$00
        byte    $00,$00,$ff,$ff,$00,$00,$00,$00
        byte    $00,$ff,$ff,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$ff,$ff,$00,$00
        byte    $30,$30,$30,$30,$30,$30,$30,$30
        byte    $0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
        byte    $00,$00,$00,$e0,$f0,$38,$18,$18
        byte    $18,$18,$1c,$0f,$07,$00,$00,$00
        byte    $18,$18,$38,$f0,$e0,$00,$00,$00
        byte    $c0,$c0,$c0,$c0,$c0,$c0,$ff,$ff
        byte    $c0,$e0,$70,$38,$1c,$0e,$07,$03
        byte    $03,$07,$0e,$1c,$38,$70,$e0,$c0
        byte    $ff,$ff,$c0,$c0,$c0,$c0,$c0,$c0
        byte    $ff,$ff,$03,$03,$03,$03,$03,$03
        byte    $00,$3c,$7e,$7e,$7e,$7e,$3c,$00
        byte    $00,$00,$00,$00,$00,$ff,$ff,$00
        byte    $36,$7f,$7f,$7f,$3e,$1c,$08,$00
        byte    $60,$60,$60,$60,$60,$60,$60,$60
        byte    $00,$00,$00,$07,$0f,$1c,$18,$18
        byte    $c3,$e7,$7e,$3c,$3c,$7e,$e7,$c3
        byte    $00,$3c,$7e,$66,$66,$7e,$3c,$00
        byte    $18,$18,$66,$66,$18,$18,$3c,$00
        byte    $06,$06,$06,$06,$06,$06,$06,$06
        byte    $08,$1c,$3e,$7f,$3e,$1c,$08,$00
        byte    $18,$18,$18,$ff,$ff,$18,$18,$18
        byte    $c0,$c0,$30,$30,$c0,$c0,$30,$30
        byte    $18,$18,$18,$18,$18,$18,$18,$18
        byte    $00,$00,$03,$3e,$76,$36,$36,$00
        byte    $ff,$7f,$3f,$1f,$0f,$07,$03,$01
        byte    $00,$00,$00,$00,$00,$00,$00,$00
        byte    $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
        byte    $00,$00,$00,$00,$ff,$ff,$ff,$ff
        byte    $ff,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$ff
        byte    $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
        byte    $cc,$cc,$33,$33,$cc,$cc,$33,$33
        byte    $03,$03,$03,$03,$03,$03,$03,$03
        byte    $00,$00,$00,$00,$cc,$cc,$33,$33
        byte    $ff,$fe,$fc,$f8,$f0,$e0,$c0,$80
        byte    $03,$03,$03,$03,$03,$03,$03,$03
        byte    $18,$18,$18,$1f,$1f,$18,$18,$18
        byte    $00,$00,$00,$00,$0f,$0f,$0f,$0f
        byte    $18,$18,$18,$1f,$1f,$00,$00,$00
        byte    $00,$00,$00,$f8,$f8,$18,$18,$18
        byte    $00,$00,$00,$00,$00,$00,$ff,$ff
        byte    $00,$00,$00,$1f,$1f,$18,$18,$18
        byte    $18,$18,$18,$ff,$ff,$00,$00,$00
        byte    $00,$00,$00,$ff,$ff,$18,$18,$18
        byte    $18,$18,$18,$f8,$f8,$18,$18,$18
        byte    $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
        byte    $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
        byte    $07,$07,$07,$07,$07,$07,$07,$07
        byte    $ff,$ff,$00,$00,$00,$00,$00,$00
        byte    $ff,$ff,$ff,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$ff,$ff,$ff
        byte    $03,$03,$03,$03,$03,$03,$ff,$ff
        byte    $00,$00,$00,$00,$f0,$f0,$f0,$f0
        byte    $0f,$0f,$0f,$0f,$00,$00,$00,$00
        byte    $18,$18,$18,$f8,$f8,$00,$00,$00
        byte    $f0,$f0,$f0,$f0,$00,$00,$00,$00
        byte    $f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f
        byte    $c3,$99,$91,$91,$9f,$99,$c3,$ff
        byte    $e7,$c3,$99,$81,$99,$99,$99,$ff
        byte    $83,$99,$99,$83,$99,$99,$83,$ff
        byte    $c3,$99,$9f,$9f,$9f,$99,$c3,$ff
        byte    $87,$93,$99,$99,$99,$93,$87,$ff
        byte    $81,$9f,$9f,$87,$9f,$9f,$81,$ff
        byte    $81,$9f,$9f,$87,$9f,$9f,$9f,$ff
        byte    $c3,$99,$9f,$91,$99,$99,$c3,$ff
        byte    $99,$99,$99,$81,$99,$99,$99,$ff
        byte    $c3,$e7,$e7,$e7,$e7,$e7,$c3,$ff
        byte    $e1,$f3,$f3,$f3,$f3,$93,$c7,$ff
        byte    $99,$93,$87,$8f,$87,$93,$99,$ff
        byte    $9f,$9f,$9f,$9f,$9f,$9f,$81,$ff
        byte    $9c,$88,$80,$94,$9c,$9c,$9c,$ff
        byte    $99,$89,$81,$81,$91,$99,$99,$ff
        byte    $c3,$99,$99,$99,$99,$99,$c3,$ff
        byte    $83,$99,$99,$83,$9f,$9f,$9f,$ff
        byte    $c3,$99,$99,$99,$99,$c3,$f1,$ff
        byte    $83,$99,$99,$83,$87,$93,$99,$ff
        byte    $c3,$99,$9f,$c3,$f9,$99,$c3,$ff
        byte    $81,$e7,$e7,$e7,$e7,$e7,$e7,$ff
        byte    $99,$99,$99,$99,$99,$99,$c3,$ff
        byte    $99,$99,$99,$99,$99,$c3,$e7,$ff
        byte    $9c,$9c,$9c,$94,$80,$88,$9c,$ff
        byte    $99,$99,$c3,$e7,$c3,$99,$99,$ff
        byte    $99,$99,$99,$c3,$e7,$e7,$e7,$ff
        byte    $81,$f9,$f3,$e7,$cf,$9f,$81,$ff
        byte    $c3,$cf,$cf,$cf,$cf,$cf,$c3,$ff
        byte    $f3,$ed,$cf,$83,$cf,$9d,$03,$ff
        byte    $c3,$f3,$f3,$f3,$f3,$f3,$c3,$ff
        byte    $ff,$e7,$c3,$81,$e7,$e7,$e7,$e7
        byte    $ff,$ef,$cf,$80,$80,$cf,$ef,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $e7,$e7,$e7,$e7,$ff,$ff,$e7,$ff
        byte    $99,$99,$99,$ff,$ff,$ff,$ff,$ff
        byte    $99,$99,$00,$99,$00,$99,$99,$ff
        byte    $e7,$c1,$9f,$c3,$f9,$83,$e7,$ff
        byte    $9d,$99,$f3,$e7,$cf,$99,$b9,$ff
        byte    $c3,$99,$c3,$c7,$98,$99,$c0,$ff
        byte    $f9,$f3,$e7,$ff,$ff,$ff,$ff,$ff
        byte    $f3,$e7,$cf,$cf,$cf,$e7,$f3,$ff
        byte    $cf,$e7,$f3,$f3,$f3,$e7,$cf,$ff
        byte    $ff,$99,$c3,$00,$c3,$99,$ff,$ff
        byte    $ff,$e7,$e7,$81,$e7,$e7,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$e7,$e7,$cf
        byte    $ff,$ff,$ff,$81,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$e7,$e7,$ff
        byte    $ff,$fc,$f9,$f3,$e7,$cf,$9f,$ff
        byte    $c3,$99,$91,$89,$99,$99,$c3,$ff
        byte    $e7,$e7,$c7,$e7,$e7,$e7,$81,$ff
        byte    $c3,$99,$f9,$f3,$cf,$9f,$81,$ff
        byte    $c3,$99,$f9,$e3,$f9,$99,$c3,$ff
        byte    $f9,$f1,$e1,$99,$80,$f9,$f9,$ff
        byte    $81,$9f,$83,$f9,$f9,$99,$c3,$ff
        byte    $c3,$99,$9f,$83,$99,$99,$c3,$ff
        byte    $81,$99,$f3,$e7,$e7,$e7,$e7,$ff
        byte    $c3,$99,$99,$c3,$99,$99,$c3,$ff
        byte    $c3,$99,$99,$c1,$f9,$99,$c3,$ff
        byte    $ff,$ff,$e7,$ff,$ff,$e7,$ff,$ff
        byte    $ff,$ff,$e7,$ff,$ff,$e7,$e7,$cf
        byte    $f1,$e7,$cf,$9f,$cf,$e7,$f1,$ff
        byte    $ff,$ff,$81,$ff,$81,$ff,$ff,$ff
        byte    $8f,$e7,$f3,$f9,$f3,$e7,$8f,$ff
        byte    $c3,$99,$f9,$f3,$e7,$ff,$e7,$ff
        byte    $ff,$ff,$ff,$00,$00,$ff,$ff,$ff
        byte    $f7,$e3,$c1,$80,$80,$e3,$c1,$ff
        byte    $e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7
        byte    $ff,$ff,$ff,$00,$00,$ff,$ff,$ff
        byte    $ff,$ff,$00,$00,$ff,$ff,$ff,$ff
        byte    $ff,$00,$00,$ff,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$00,$00,$ff,$ff
        byte    $cf,$cf,$cf,$cf,$cf,$cf,$cf,$cf
        byte    $f3,$f3,$f3,$f3,$f3,$f3,$f3,$f3
        byte    $ff,$ff,$ff,$1f,$0f,$c7,$e7,$e7
        byte    $e7,$e7,$e3,$f0,$f8,$ff,$ff,$ff
        byte    $e7,$e7,$c7,$0f,$1f,$ff,$ff,$ff
        byte    $3f,$3f,$3f,$3f,$3f,$3f,$00,$00
        byte    $3f,$1f,$8f,$c7,$e3,$f1,$f8,$fc
        byte    $fc,$f8,$f1,$e3,$c7,$8f,$1f,$3f
        byte    $00,$00,$3f,$3f,$3f,$3f,$3f,$3f
        byte    $00,$00,$fc,$fc,$fc,$fc,$fc,$fc
        byte    $ff,$c3,$81,$81,$81,$81,$c3,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$00,$00,$ff
        byte    $c9,$80,$80,$80,$c1,$e3,$f7,$ff
        byte    $9f,$9f,$9f,$9f,$9f,$9f,$9f,$9f
        byte    $ff,$ff,$ff,$f8,$f0,$e3,$e7,$e7
        byte    $3c,$18,$81,$c3,$c3,$81,$18,$3c
        byte    $ff,$c3,$81,$99,$99,$81,$c3,$ff
        byte    $e7,$e7,$99,$99,$e7,$e7,$c3,$ff
        byte    $f9,$f9,$f9,$f9,$f9,$f9,$f9,$f9
        byte    $f7,$e3,$c1,$80,$c1,$e3,$f7,$ff
        byte    $e7,$e7,$e7,$00,$00,$e7,$e7,$e7
        byte    $3f,$3f,$cf,$cf,$3f,$3f,$cf,$cf
        byte    $e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7
        byte    $ff,$ff,$fc,$c1,$89,$c9,$c9,$ff
        byte    $00,$80,$c0,$e0,$f0,$f8,$fc,$fe
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        byte    $ff,$ff,$ff,$ff,$00,$00,$00,$00
        byte    $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
        byte    $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
        byte    $33,$33,$cc,$cc,$33,$33,$cc,$cc
        byte    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        byte    $ff,$ff,$ff,$ff,$33,$33,$cc,$cc
        byte    $00,$01,$03,$07,$0f,$1f,$3f,$7f
        byte    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        byte    $e7,$e7,$e7,$e0,$e0,$e7,$e7,$e7
        byte    $ff,$ff,$ff,$ff,$f0,$f0,$f0,$f0
        byte    $e7,$e7,$e7,$e0,$e0,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$07,$07,$e7,$e7,$e7
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$00,$00
        byte    $ff,$ff,$ff,$e0,$e0,$e7,$e7,$e7
        byte    $e7,$e7,$e7,$00,$00,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$00,$00,$e7,$e7,$e7
        byte    $e7,$e7,$e7,$07,$07,$e7,$e7,$e7
        byte    $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
        byte    $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
        byte    $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
        byte    $00,$00,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $00,$00,$00,$ff,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$00,$00,$00
        byte    $fc,$fc,$fc,$fc,$fc,$fc,$00,$00
        byte    $ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f
        byte    $f0,$f0,$f0,$f0,$ff,$ff,$ff,$ff
        byte    $e7,$e7,$e7,$07,$07,$ff,$ff,$ff
        byte    $0f,$0f,$0f,$0f,$ff,$ff,$ff,$ff
        byte    $0f,$0f,$0f,$0f,$f0,$f0,$f0,$f0

CHARS_LOWER
        byte    $3c,$66,$6e,$6e,$60,$62,$3c,$00
        byte    $00,$00,$3c,$06,$3e,$66,$3e,$00
        byte    $00,$60,$60,$7c,$66,$66,$7c,$00
        byte    $00,$00,$3c,$60,$60,$60,$3c,$00
        byte    $00,$06,$06,$3e,$66,$66,$3e,$00
        byte    $00,$00,$3c,$66,$7e,$60,$3c,$00
        byte    $00,$0e,$18,$3e,$18,$18,$18,$00
        byte    $00,$00,$3e,$66,$66,$3e,$06,$7c
        byte    $00,$60,$60,$7c,$66,$66,$66,$00
        byte    $00,$18,$00,$38,$18,$18,$3c,$00
        byte    $00,$06,$00,$06,$06,$06,$06,$3c
        byte    $00,$60,$60,$6c,$78,$6c,$66,$00
        byte    $00,$38,$18,$18,$18,$18,$3c,$00
        byte    $00,$00,$66,$7f,$7f,$6b,$63,$00
        byte    $00,$00,$7c,$66,$66,$66,$66,$00
        byte    $00,$00,$3c,$66,$66,$66,$3c,$00
        byte    $00,$00,$7c,$66,$66,$7c,$60,$60
        byte    $00,$00,$3e,$66,$66,$3e,$06,$06
        byte    $00,$00,$7c,$66,$60,$60,$60,$00
        byte    $00,$00,$3e,$60,$3c,$06,$7c,$00
        byte    $00,$18,$7e,$18,$18,$18,$0e,$00
        byte    $00,$00,$66,$66,$66,$66,$3e,$00
        byte    $00,$00,$66,$66,$66,$3c,$18,$00
        byte    $00,$00,$63,$6b,$7f,$3e,$36,$00
        byte    $00,$00,$66,$3c,$18,$3c,$66,$00
        byte    $00,$00,$66,$66,$66,$3e,$0c,$78
        byte    $00,$00,$7e,$0c,$18,$30,$7e,$00
        byte    $3c,$30,$30,$30,$30,$30,$3c,$00
        byte    $0c,$12,$30,$7c,$30,$62,$fc,$00
        byte    $3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
        byte    $00,$18,$3c,$7e,$18,$18,$18,$18
        byte    $00,$10,$30,$7f,$7f,$30,$10,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00
        byte    $18,$18,$18,$18,$00,$00,$18,$00
        byte    $66,$66,$66,$00,$00,$00,$00,$00
        byte    $66,$66,$ff,$66,$ff,$66,$66,$00
        byte    $18,$3e,$60,$3c,$06,$7c,$18,$00
        byte    $62,$66,$0c,$18,$30,$66,$46,$00
        byte    $3c,$66,$3c,$38,$67,$66,$3f,$00
        byte    $06,$0c,$18,$00,$00,$00,$00,$00
        byte    $0c,$18,$30,$30,$30,$18,$0c,$00
        byte    $30,$18,$0c,$0c,$0c,$18,$30,$00
        byte    $00,$66,$3c,$ff,$3c,$66,$00,$00
        byte    $00,$18,$18,$7e,$18,$18,$00,$00
        byte    $00,$00,$00,$00,$00,$18,$18,$30
        byte    $00,$00,$00,$7e,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$18,$18,$00
        byte    $00,$03,$06,$0c,$18,$30,$60,$00
        byte    $3c,$66,$6e,$76,$66,$66,$3c,$00
        byte    $18,$18,$38,$18,$18,$18,$7e,$00
        byte    $3c,$66,$06,$0c,$30,$60,$7e,$00
        byte    $3c,$66,$06,$1c,$06,$66,$3c,$00
        byte    $06,$0e,$1e,$66,$7f,$06,$06,$00
        byte    $7e,$60,$7c,$06,$06,$66,$3c,$00
        byte    $3c,$66,$60,$7c,$66,$66,$3c,$00
        byte    $7e,$66,$0c,$18,$18,$18,$18,$00
        byte    $3c,$66,$66,$3c,$66,$66,$3c,$00
        byte    $3c,$66,$66,$3e,$06,$66,$3c,$00
        byte    $00,$00,$18,$00,$00,$18,$00,$00
        byte    $00,$00,$18,$00,$00,$18,$18,$30
        byte    $0e,$18,$30,$60,$30,$18,$0e,$00
        byte    $00,$00,$7e,$00,$7e,$00,$00,$00
        byte    $70,$18,$0c,$06,$0c,$18,$70,$00
        byte    $3c,$66,$06,$0c,$18,$00,$18,$00
        byte    $00,$00,$00,$ff,$ff,$00,$00,$00
        byte    $18,$3c,$66,$7e,$66,$66,$66,$00
        byte    $7c,$66,$66,$7c,$66,$66,$7c,$00
        byte    $3c,$66,$60,$60,$60,$66,$3c,$00
        byte    $78,$6c,$66,$66,$66,$6c,$78,$00
        byte    $7e,$60,$60,$78,$60,$60,$7e,$00
        byte    $7e,$60,$60,$78,$60,$60,$60,$00
        byte    $3c,$66,$60,$6e,$66,$66,$3c,$00
        byte    $66,$66,$66,$7e,$66,$66,$66,$00
        byte    $3c,$18,$18,$18,$18,$18,$3c,$00
        byte    $1e,$0c,$0c,$0c,$0c,$6c,$38,$00
        byte    $66,$6c,$78,$70,$78,$6c,$66,$00
        byte    $60,$60,$60,$60,$60,$60,$7e,$00
        byte    $63,$77,$7f,$6b,$63,$63,$63,$00
        byte    $66,$76,$7e,$7e,$6e,$66,$66,$00
        byte    $3c,$66,$66,$66,$66,$66,$3c,$00
        byte    $7c,$66,$66,$7c,$60,$60,$60,$00
        byte    $3c,$66,$66,$66,$66,$3c,$0e,$00
        byte    $7c,$66,$66,$7c,$78,$6c,$66,$00
        byte    $3c,$66,$60,$3c,$06,$66,$3c,$00
        byte    $7e,$18,$18,$18,$18,$18,$18,$00
        byte    $66,$66,$66,$66,$66,$66,$3c,$00
        byte    $66,$66,$66,$66,$66,$3c,$18,$00
        byte    $63,$63,$63,$6b,$7f,$77,$63,$00
        byte    $66,$66,$3c,$18,$3c,$66,$66,$00
        byte    $66,$66,$66,$3c,$18,$18,$18,$00
        byte    $7e,$06,$0c,$18,$30,$60,$7e,$00
        byte    $18,$18,$18,$ff,$ff,$18,$18,$18
        byte    $c0,$c0,$30,$30,$c0,$c0,$30,$30
        byte    $18,$18,$18,$18,$18,$18,$18,$18
        byte    $33,$33,$cc,$cc,$33,$33,$cc,$cc
        byte    $33,$99,$cc,$66,$33,$99,$cc,$66
        byte    $00,$00,$00,$00,$00,$00,$00,$00
        byte    $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
        byte    $00,$00,$00,$00,$ff,$ff,$ff,$ff
        byte    $ff,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$ff
        byte    $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
        byte    $cc,$cc,$33,$33,$cc,$cc,$33,$33
        byte    $03,$03,$03,$03,$03,$03,$03,$03
        byte    $00,$00,$00,$00,$cc,$cc,$33,$33
        byte    $cc,$99,$33,$66,$cc,$99,$33,$66
        byte    $03,$03,$03,$03,$03,$03,$03,$03
        byte    $18,$18,$18,$1f,$1f,$18,$18,$18
        byte    $00,$00,$00,$00,$0f,$0f,$0f,$0f
        byte    $18,$18,$18,$1f,$1f,$00,$00,$00
        byte    $00,$00,$00,$f8,$f8,$18,$18,$18
        byte    $00,$00,$00,$00,$00,$00,$ff,$ff
        byte    $00,$00,$00,$1f,$1f,$18,$18,$18
        byte    $18,$18,$18,$ff,$ff,$00,$00,$00
        byte    $00,$00,$00,$ff,$ff,$18,$18,$18
        byte    $18,$18,$18,$f8,$f8,$18,$18,$18
        byte    $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
        byte    $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
        byte    $07,$07,$07,$07,$07,$07,$07,$07
        byte    $ff,$ff,$00,$00,$00,$00,$00,$00
        byte    $ff,$ff,$ff,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$ff,$ff,$ff
        byte    $01,$03,$06,$6c,$78,$70,$60,$00
        byte    $00,$00,$00,$00,$f0,$f0,$f0,$f0
        byte    $0f,$0f,$0f,$0f,$00,$00,$00,$00
        byte    $18,$18,$18,$f8,$f8,$00,$00,$00
        byte    $f0,$f0,$f0,$f0,$00,$00,$00,$00
        byte    $f0,$f0,$f0,$f0,$0f,$0f,$0f,$0f
        byte    $c3,$99,$91,$91,$9f,$99,$c3,$ff
        byte    $ff,$ff,$c3,$f9,$c1,$99,$c1,$ff
        byte    $ff,$9f,$9f,$83,$99,$99,$83,$ff
        byte    $ff,$ff,$c3,$9f,$9f,$9f,$c3,$ff
        byte    $ff,$f9,$f9,$c1,$99,$99,$c1,$ff
        byte    $ff,$ff,$c3,$99,$81,$9f,$c3,$ff
        byte    $ff,$f1,$e7,$c1,$e7,$e7,$e7,$ff
        byte    $ff,$ff,$c1,$99,$99,$c1,$f9,$83
        byte    $ff,$9f,$9f,$83,$99,$99,$99,$ff
        byte    $ff,$e7,$ff,$c7,$e7,$e7,$c3,$ff
        byte    $ff,$f9,$ff,$f9,$f9,$f9,$f9,$c3
        byte    $ff,$9f,$9f,$93,$87,$93,$99,$ff
        byte    $ff,$c7,$e7,$e7,$e7,$e7,$c3,$ff
        byte    $ff,$ff,$99,$80,$80,$94,$9c,$ff
        byte    $ff,$ff,$83,$99,$99,$99,$99,$ff
        byte    $ff,$ff,$c3,$99,$99,$99,$c3,$ff
        byte    $ff,$ff,$83,$99,$99,$83,$9f,$9f
        byte    $ff,$ff,$c1,$99,$99,$c1,$f9,$f9
        byte    $ff,$ff,$83,$99,$9f,$9f,$9f,$ff
        byte    $ff,$ff,$c1,$9f,$c3,$f9,$83,$ff
        byte    $ff,$e7,$81,$e7,$e7,$e7,$f1,$ff
        byte    $ff,$ff,$99,$99,$99,$99,$c1,$ff
        byte    $ff,$ff,$99,$99,$99,$c3,$e7,$ff
        byte    $ff,$ff,$9c,$94,$80,$c1,$c9,$ff
        byte    $ff,$ff,$99,$c3,$e7,$c3,$99,$ff
        byte    $ff,$ff,$99,$99,$99,$c1,$f3,$87
        byte    $ff,$ff,$81,$f3,$e7,$cf,$81,$ff
        byte    $c3,$cf,$cf,$cf,$cf,$cf,$c3,$ff
        byte    $f3,$ed,$cf,$83,$cf,$9d,$03,$ff
        byte    $c3,$f3,$f3,$f3,$f3,$f3,$c3,$ff
        byte    $ff,$e7,$c3,$81,$e7,$e7,$e7,$e7
        byte    $ff,$ef,$cf,$80,$80,$cf,$ef,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $e7,$e7,$e7,$e7,$ff,$ff,$e7,$ff
        byte    $99,$99,$99,$ff,$ff,$ff,$ff,$ff
        byte    $99,$99,$00,$99,$00,$99,$99,$ff
        byte    $e7,$c1,$9f,$c3,$f9,$83,$e7,$ff
        byte    $9d,$99,$f3,$e7,$cf,$99,$b9,$ff
        byte    $c3,$99,$c3,$c7,$98,$99,$c0,$ff
        byte    $f9,$f3,$e7,$ff,$ff,$ff,$ff,$ff
        byte    $f3,$e7,$cf,$cf,$cf,$e7,$f3,$ff
        byte    $cf,$e7,$f3,$f3,$f3,$e7,$cf,$ff
        byte    $ff,$99,$c3,$00,$c3,$99,$ff,$ff
        byte    $ff,$e7,$e7,$81,$e7,$e7,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$e7,$e7,$cf
        byte    $ff,$ff,$ff,$81,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$e7,$e7,$ff
        byte    $ff,$fc,$f9,$f3,$e7,$cf,$9f,$ff
        byte    $c3,$99,$91,$89,$99,$99,$c3,$ff
        byte    $e7,$e7,$c7,$e7,$e7,$e7,$81,$ff
        byte    $c3,$99,$f9,$f3,$cf,$9f,$81,$ff
        byte    $c3,$99,$f9,$e3,$f9,$99,$c3,$ff
        byte    $f9,$f1,$e1,$99,$80,$f9,$f9,$ff
        byte    $81,$9f,$83,$f9,$f9,$99,$c3,$ff
        byte    $c3,$99,$9f,$83,$99,$99,$c3,$ff
        byte    $81,$99,$f3,$e7,$e7,$e7,$e7,$ff
        byte    $c3,$99,$99,$c3,$99,$99,$c3,$ff
        byte    $c3,$99,$99,$c1,$f9,$99,$c3,$ff
        byte    $ff,$ff,$e7,$ff,$ff,$e7,$ff,$ff
        byte    $ff,$ff,$e7,$ff,$ff,$e7,$e7,$cf
        byte    $f1,$e7,$cf,$9f,$cf,$e7,$f1,$ff
        byte    $ff,$ff,$81,$ff,$81,$ff,$ff,$ff
        byte    $8f,$e7,$f3,$f9,$f3,$e7,$8f,$ff
        byte    $c3,$99,$f9,$f3,$e7,$ff,$e7,$ff
        byte    $ff,$ff,$ff,$00,$00,$ff,$ff,$ff
        byte    $e7,$c3,$99,$81,$99,$99,$99,$ff
        byte    $83,$99,$99,$83,$99,$99,$83,$ff
        byte    $c3,$99,$9f,$9f,$9f,$99,$c3,$ff
        byte    $87,$93,$99,$99,$99,$93,$87,$ff
        byte    $81,$9f,$9f,$87,$9f,$9f,$81,$ff
        byte    $81,$9f,$9f,$87,$9f,$9f,$9f,$ff
        byte    $c3,$99,$9f,$91,$99,$99,$c3,$ff
        byte    $99,$99,$99,$81,$99,$99,$99,$ff
        byte    $c3,$e7,$e7,$e7,$e7,$e7,$c3,$ff
        byte    $e1,$f3,$f3,$f3,$f3,$93,$c7,$ff
        byte    $99,$93,$87,$8f,$87,$93,$99,$ff
        byte    $9f,$9f,$9f,$9f,$9f,$9f,$81,$ff
        byte    $9c,$88,$80,$94,$9c,$9c,$9c,$ff
        byte    $99,$89,$81,$81,$91,$99,$99,$ff
        byte    $c3,$99,$99,$99,$99,$99,$c3,$ff
        byte    $83,$99,$99,$83,$9f,$9f,$9f,$ff
        byte    $c3,$99,$99,$99,$99,$c3,$f1,$ff
        byte    $83,$99,$99,$83,$87,$93,$99,$ff
        byte    $c3,$99,$9f,$c3,$f9,$99,$c3,$ff
        byte    $81,$e7,$e7,$e7,$e7,$e7,$e7,$ff
        byte    $99,$99,$99,$99,$99,$99,$c3,$ff
        byte    $99,$99,$99,$99,$99,$c3,$e7,$ff
        byte    $9c,$9c,$9c,$94,$80,$88,$9c,$ff
        byte    $99,$99,$c3,$e7,$c3,$99,$99,$ff
        byte    $99,$99,$99,$c3,$e7,$e7,$e7,$ff
        byte    $81,$f9,$f3,$e7,$cf,$9f,$81,$ff
        byte    $e7,$e7,$e7,$00,$00,$e7,$e7,$e7
        byte    $3f,$3f,$cf,$cf,$3f,$3f,$cf,$cf
        byte    $e7,$e7,$e7,$e7,$e7,$e7,$e7,$e7
        byte    $cc,$cc,$33,$33,$cc,$cc,$33,$33
        byte    $cc,$66,$33,$99,$cc,$66,$33,$99
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        byte    $ff,$ff,$ff,$ff,$00,$00,$00,$00
        byte    $00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
        byte    $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
        byte    $33,$33,$cc,$cc,$33,$33,$cc,$cc
        byte    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        byte    $ff,$ff,$ff,$ff,$33,$33,$cc,$cc
        byte    $33,$66,$cc,$99,$33,$66,$cc,$99
        byte    $fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
        byte    $e7,$e7,$e7,$e0,$e0,$e7,$e7,$e7
        byte    $ff,$ff,$ff,$ff,$f0,$f0,$f0,$f0
        byte    $e7,$e7,$e7,$e0,$e0,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$07,$07,$e7,$e7,$e7
        byte    $ff,$ff,$ff,$ff,$ff,$ff,$00,$00
        byte    $ff,$ff,$ff,$e0,$e0,$e7,$e7,$e7
        byte    $e7,$e7,$e7,$00,$00,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$00,$00,$e7,$e7,$e7
        byte    $e7,$e7,$e7,$07,$07,$e7,$e7,$e7
        byte    $3f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
        byte    $1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f
        byte    $f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
        byte    $00,$00,$ff,$ff,$ff,$ff,$ff,$ff
        byte    $00,$00,$00,$ff,$ff,$ff,$ff,$ff
        byte    $ff,$ff,$ff,$ff,$ff,$00,$00,$00
        byte    $fe,$fc,$f9,$93,$87,$8f,$9f,$ff
        byte    $ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f
        byte    $f0,$f0,$f0,$f0,$ff,$ff,$ff,$ff
        byte    $e7,$e7,$e7,$07,$07,$ff,$ff,$ff
        byte    $0f,$0f,$0f,$0f,$ff,$ff,$ff,$ff
        byte    $0f,$0f,$0f,$0f,$f0,$f0,$f0,$f0
       
; Screen 1 - Term window Screen data
Term_window_screen_data
        BYTE    $3A,$20,$46,$31,$2D,$4D,$05,$0E,$15,$20,$46,$32,$2D,$06,$15,$14,$15,$12,$05,$2E,$2E,$2E
        BYTE    $5D,$20,$46,$33,$2D,$54,$05,$12,$0D,$20,$46,$34,$2D,$48,$01,$0E,$07,$15,$10,$20,$20,$20
        BYTE    $6D,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20

; Screen 1 - Term window Colour data
Term_window_colour_data
        BYTE    $07,$02,$02,$02,$01,$05,$05,$05,$05,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$01,$01,$01
        BYTE    $07,$02,$02,$02,$01,$05,$05,$05,$05,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$00,$00
        BYTE    $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Screen 1 - Options Screen data
Options_screen_data
        BYTE    $70,$40,$40,$40,$40,$40,$4E,$09,$0E,$0A,$01,$20,$54,$05,$12,$0D,$40,$40,$40,$40,$40,$40
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $5D,$20,$46,$31,$2D,$42,$01,$15,$04,$20,$52,$01,$14,$05,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $5D,$20,$46,$32,$2D,$06,$15,$14,$15,$12,$05,$2E,$2E,$2E,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$2E
        BYTE    $5D,$20,$46,$33,$2D,$52,$05,$14,$15,$12,$0E,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$3A
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$3A
        BYTE    $5D,$20,$46,$34,$2D,$48,$01,$0E,$07,$20,$55,$10,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $5D,$20,$46,$35,$2D,$06,$15,$14,$15,$12,$05,$2E,$2E,$2E,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $5D,$20,$46,$36,$2D,$44,$05,$06,$01,$15,$0C,$14,$13,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $5D,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $3A,$20,$46,$37,$2D,$4C,$0F,$17,$05,$12,$20,$43,$01,$13,$05,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $3A,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $2E,$20,$46,$38,$2D,$55,$10,$10,$05,$12,$20,$43,$01,$13,$05,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $20,$20,$41,$4C,$54,$49,$57,$4F,$52,$4C,$44,$2E,$43,$4F,$4D,$3A,$36,$34,$30,$30,$20,$5D
        BYTE    $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$5D
        BYTE    $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$7D

; Screen 1 - Options Colour data
Options_colour_data
        BYTE    $07,$07,$07,$07,$07,$07,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$07,$07,$07,$07,$07,$07
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$01,$01,$01,$05,$05,$05,$05,$00,$00,$00,$07
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$00,$02,$02,$01,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$00,$00,$00,$00,$00,$00,$07
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $00,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$00,$07
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
        BYTE    $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07

