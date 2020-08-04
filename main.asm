#include "p16f882.inc"
    errorlevel -302
    
; CONFIG1
; __config 0x20F2
 __CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
; IO Configuration Constants
; -------------------------- 
; PORT A
; Bit 0	 OUT   LCD D4 
; Bit 1	 OUT   LCD D5 
; Bit 2	 OUT   LCD D6 
; Bit 3	 OUT   LCD D7 
; Bit 4	 IN   
; Bit 5	 IN   
; Bit 6	 IN   
; Bit 7	 IN   
PORTATRIS	equ 0xf0
LCD_D4		equ	0
LCD_D5		equ	1
LCD_D6		equ	2
LCD_D7		equ	3
LCD_DATA	equ	PORTA	    
LCD_DATA_SH	equ	0x20
LCD_SH_MASK	equ	0xf0
	    
; PORT B 
; Bit 0	 OUT   LCD RS - Register Select
; Bit 1	 OUT   LCD EN - Enable
; Bit 2	 OUT   GATE
; Bit 3	 IN   
; Bit 4	 IN   
; Bit 5	 IN   
; Bit 6	 IN   
; Bit 7	 IN   
PORTBTRIS	equ 0xf8
LCD_RS		equ	0
LCD_EN		equ	1
LCD_CONTROL	equ	PORTB	    
LCD_CONTROL_SH	equ	0x21	    
GATE		equ	2	
	    
; General Purpose Registers
portASh	    equ 0x20	; Port A Shadow register
portBSh	    equ 0x21	; Port B Shadow register
delay1	    equ	0x22	; Delay routines
delay2	    equ	0x23	; Delay routines
delay3	    equ	0x24	; Delay routines
delay4	    equ	0x25	; Delay routines
	    
lcd_byte    equ	0x27	; Temp storage when sending a byte in 4 bit mode
lcd_tmpw    equ	0x28	; Temp w value when sending commands and data    
lcd_sh_tmp  equ	0x29	; Temp value when updating shadow register
debug	    equ	0x2a    

byte0	    equ	0x30	; BCD - in - low byte
byte1	    equ	0x31
byte2	    equ	0x32
byte3	    equ	0x33	; BCD - in - high byte
   
r0	    equ	0x34	; BCD - out
r1	    equ	0x35
r2	    equ	0x36
r3	    equ	0x37
r4	    equ	0x38
count	    equ	0x39
temp	    equ	0x3a

counterB0   equ	0x40	; Counter - low byte
counterB1   equ	0x41
counterB2   equ	0x42
counterB3   equ	0x43	; Counter - high byte
 
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program


MAIN_PROG CODE                      ; let linker place main program

START 
 
    ; ****************************************************************
    ; * INITIALISATION                                               *
    ; * --------------                                               *
    ; *   Ports                                                      *
    ; *   LCD                                                        *
    ; *   Timers                                                     *
    ; ****************************************************************

    ; Ports A and B used for IO
	banksel	PORTA 
	clrf	PORTA
	clrf	portASh
	banksel	PORTB 
	clrf	PORTB
	clrf	portBSh
	banksel ANSEL 
	clrf	ANSEL
	banksel ANSELH 
	clrf	ANSELH
	banksel TRISA
	movlw	PORTATRIS
	movwf	TRISA
	banksel TRISB
	movlw	PORTBTRIS
	movwf	TRISB
	banksel PORTA
	
    ; Port C
	banksel	PORTC
	clrf	PORTC
	banksel TRISC
	movlw	0x01
	movwf	TRISC
	banksel	PORTA
	
	
    ; LCD	
	call	LCD_Init
	call	CNTR_Clear

    ; Timer 1
	movlw	0x46	;  active low gate, external clock, not runnng
	movwf	T1CON
	movlw	0x00	; Clear timer to 0
	movwf	TMR1H
	movwf	TMR1L
	
    ; ****************************************************************
    ; * WELCOME                                                      *
    ; * -------                                                      *
    ; *   Display message and version                                *
    ; ****************************************************************
	

    ; ****************************************************************
    ; * MAIN LOOP                                                    *
    ; * ---------                                                    *
    ; *   Measure and display frequency                              *
    ; ****************************************************************
    
	call	LCD_Line1
	movlw	'H'
	call	LCD_Char
	movlw	'e'
	call	LCD_Char
	movlw	'l'
	call	LCD_Char
	movlw	'l'
	call	LCD_Char
	movlw	'o'
	call	LCD_Char
	movlw	' '
	call	LCD_Char
	movlw	'W'
	call	LCD_Char
	movlw	'o'
	call	LCD_Char
	movlw	'r'
	call	LCD_Char
	movlw	'l'
	call	LCD_Char
	movlw	'd'
	call	LCD_Char

	call	LCD_Line2
	call	ToBCD
	call	LCD_BCD
   
    ; Basic loop with a 10ms gate period
    ; Start Timer
fcount	bsf	T1CON,0
	bcf	portBSh,GATE
	movfw	portBSh
	movwf	PORTB
	call	Delay10ms
	bsf	portBSh,GATE
	movfw	portBSh
	movwf	PORTB
	; call	Delay10ms
	
; Stop timer
        bcf	T1CON,0

; Grab current timer counts
	movfw	TMR1H
	movwf	counterB1
	movfw	TMR1L
	movwf	counterB0

; clear the timer	
	movlw	0
	movwf	TMR1H
	movwf	TMR1L
	
; Update the display
	call	LCD_Line2
    ;	call	CNTR_Inc
	call	CNTR_Copy
	call	ToBCD
	call	LCD_BCD

; Only update this display every 100ms
	call	Delay100ms
	
	goto	fcount

    ; ****************************************************************
    ; * LCD FUNCTIONS (4bit)                                         *
    ; * -------------                                                *
    ; *   The following functions are defined:                       *
    ; *   LCD_Init		Initialise LCD                       *
    ; *   LCD_Char		Write char in w to current position  *
    ; *   LCD_Line1		Goto Line 1                          *
    ; *   LCD_Line2		Goto Line 2                          *
    ; *   LCD_Clear		Clear LCD                            *
    ; *   _LCD_WriteCommand	Write command byte in w to LCD       *
    ; *   _LCD_WriteData	Write data byte in w to LCD          *
    ; *   _LCD_WriteByte	Write byte in w to LCD               *
    ; *   _LCD_WriteNibble	Write nibble in w to LCD             *
    ; ****************************************************************

; Initialise the LCD
LCD_Init    
				; Clear control lines
	bcf	LCD_CONTROL_SH,LCD_RS
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	bcf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
		
				; Wait for LCD to boot
	call	Delay10ms
	call	Delay10ms
	call	Delay10ms
	call	Delay10ms
	
				; Magic sequence to force it into 4 bit mode
	movlw	0x03
	call	_LCD_WriteNibble
	call	Delay5ms
	movlw	0x03
	call	_LCD_WriteNibble
	call	Delay5ms
	movlw	0x03
	call	_LCD_WriteNibble
	call	Delay5ms
	movlw	0x02
	call	_LCD_WriteNibble
	
				; 4 bit, 2 line, 5x8 Font
	movlw	0x28
	call	_LCD_WriteCommand
	call	Delay5ms

				; Display on, no cursor, no blinking
	movlw	0x0c
	call	_LCD_WriteCommand
	call	Delay5ms
	
	call	LCD_Clear
	call	Delay5ms
				; Left to right
	movlw	0x06
	call	_LCD_WriteCommand
	call	Delay5ms

	call	LCD_Clear
				; Ready for data
	bsf	LCD_CONTROL_SH,LCD_RS
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	
	return
    
; Write character in w at current position
LCD_Char    
	call	_LCD_WriteData
	return
    
; Goto Line 1
LCD_Line1    
	movlw	0x80
	call	_LCD_WriteCommand
	return

LCD_Line2    
	movlw	0x80 + 0x40
	call	_LCD_WriteCommand
	return
	
; Clear LCD
LCD_Clear    
	movlw	0x01
	call	_LCD_WriteCommand
	call	Delay2ms
	return
    
; Write COMMAND byte in w to LCD
_LCD_WriteCommand
	movwf	lcd_tmpw
	bcf	LCD_CONTROL_SH,LCD_RS
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	movf	lcd_tmpw,0
	goto	_LCD_WriteByte

; Write DATA byte in w to LCD
_LCD_WriteData
	movwf	lcd_tmpw
	bsf	LCD_CONTROL_SH,LCD_RS
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	movf	lcd_tmpw,0
	goto	_LCD_WriteByte
	
; Write byte in w to LCD
_LCD_WriteByte
				; Upper 4 bits
	movwf	lcd_byte
	swapf	lcd_byte,0
	andlw	0x0f
	
	movwf	lcd_sh_tmp	; Update the shadow data register
	movfw	LCD_DATA_SH
	andlw	LCD_SH_MASK
	iorwf   lcd_sh_tmp,0
	movwf   LCD_DATA_SH
	movwf	LCD_DATA
				; Set/Clear enable
	bsf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	bcf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us

				; Lower 4 bits
	movf	lcd_byte,0
	andlw	0x0f
	
	movwf	lcd_sh_tmp	; Update the shadow data register
	movfw	LCD_DATA_SH
	andlw	LCD_SH_MASK
	iorwf   lcd_sh_tmp,0
	movwf   LCD_DATA_SH
	movwf	LCD_DATA
				; Set/Clear enable
	bsf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	bcf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	
	return

; Write nibble in w to LCD
_LCD_WriteNibble
				; Lower 4 bits only
	andlw	0x0f
	
	movwf	lcd_sh_tmp	; Update the shadow data register
	movfw	LCD_DATA_SH
	andlw	LCD_SH_MASK
	iorwf   lcd_sh_tmp,0
	movwf   LCD_DATA_SH
	movwf	LCD_DATA
				; Set/clear enable
	bsf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	bcf	LCD_CONTROL_SH,LCD_EN
	movfw	LCD_CONTROL_SH
	movwf	LCD_CONTROL	
	call	Delay100us
	
	return
	
    ; ****************************************************************
    ; * DELAY FUNCTIONS (8MHz Clock)                                 *
    ; * ---------------                                              *
    ; *   The following functions are defined:                       *
    ; *   Delay1s	1 Second                                     *
    ; *   Delay100ms	100 Milliseconds                             *
    ; *   Delay10ms	10 Milliseconds                              *
    ; *   Delay5ms	5 Milliseconds                               *
    ; *   Delay2ms	2 Milliseconds                               *
    ; *   Delay100us	100 Microseconds                             *
    ; *   Delay10us	10 Microseconds                              *
    ; ****************************************************************

; Delay 1 second
Delay1s
			;1999996 cycles
	movlw	0x11
	movwf	delay1
	movlw	0x5D
	movwf	delay2
	movlw	0x05
	movwf	delay3
_Delay1s_0
	decfsz	delay1, f
	goto	$+2
	decfsz	delay2, f
	goto	$+2
	decfsz	delay3, f
	goto	_Delay1s_0

			;4 cycles (including call)
	return  

; Delay 100ms
Delay100ms
		;199993 cycles
	movlw	0x3E
	movwf	delay1
	movlw	0x9D
	movwf	delay2
_Delay_0
	decfsz	delay1, f
	goto	$+2
	decfsz	delay2, f
	goto	_Delay_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return	
	
; Delay 10ms
Delay10ms
			;19993 cycles
	movlw	0x9E
	movwf	delay1
	movlw	0x10
	movwf	delay2
_Delay10ms_0
	decfsz	delay1, f
	goto	$+2
	decfsz	delay2, f
	goto	_Delay10ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return	

; Delay 5ms
Delay5ms
			;9993 cycles
	movlw	0xCE
	movwf	delay1
	movlw	0x08
	movwf	delay2
_Delay5ms_0
	decfsz	delay1, f
	goto	$+2
	decfsz	delay2, f
	goto	_Delay5ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return	

; Delay 2ms
Delay2ms
			;3993 cycles
	movlw	0x1E
	movwf	delay1
	movlw	0x04
	movwf	delay2
_Delay2ms_0
	decfsz	delay1, f
	goto	$+2
	decfsz	delay2, f
	goto	_Delay2ms_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return	

; Delay 100us
Delay100us
			;196 cycles
	movlw	0x41
	movwf	delay1
_Delay100us_0
	decfsz	delay1, f
	goto	_Delay100us_0

			;4 cycles (including call)
	return	

; Delay 10us
Delay10us
			;16 cycles
	movlw	0x05
	movwf	delay1
_Delay10us_0
	decfsz	delay1, f
	goto	_Delay10us_0

			;4 cycles (including call)
	return	

    ; ****************************************************************
    ; * BCD FUNCTIONS 24bit                                          *
    ; * -------------------                                          *
    ; *   The following functions are defined:                       *
    ; *   ToBCD	      Convert byte0..3 to BCD in r0-r4               *
    ; *   LCD_BCD     Display BCD value                              *
    ; ****************************************************************	

ToBCD
	bcf	STATUS,C
	movlw	0x20
	movwf	count
	clrf	r0
	clrf	r1
	clrf	r2
	clrf	r3
	clrf	r4
_loop16	rlf	byte0,f
	rlf	byte1,f
	rlf	byte2,f
	rlf	byte3,f
	rlf	r0,f
	rlf	r1,f
	rlf	r2,f
	rlf	r3,f
	rlf	r4,f

	decfsz	count,1
	goto	_adjdec
	retlw	0 

_adjdec	movlw	r4
	movwf	FSR 
	call	_adjbcd
	
	movlw	r3
	movwf	FSR 
	call	_adjbcd

	movlw	r2
	movwf	FSR 
	call	_adjbcd

	movlw	r1
	movwf	FSR
	call	_adjbcd

	movlw	r0
	movwf	FSR
	call	_adjbcd

	goto	_loop16

_adjbcd	movlw	0x03
	addwf	0,w
	movwf	temp
	btfsc	temp,3
	movwf	0
	movlw	0x30
	addwf	0,w
	movwf	temp
	btfsc	temp,7
	movwf	0
	return	

	
LCD_BCD
	movlw	0x30		
	movwf	temp		;Amount to add to convert to ascii
	
				;As all numbers are BCD (1 to 9),
				;they can be converted to ASCII by 
				;simply adding 0x30 to each digit. 
	
	goto	dt1
				
	movf	r4,w		;Check the first digit for a leading zero
	andlw	0x0f
	btfss	STATUS,Z
	goto	dt1		;No LZ, display full freq.
	swapf	r3,w		;Check the second digit for leading zero.
	andlw	0x0f
	btfss	STATUS,Z
	goto	dt2
	goto	dt3
	
dt1	movf	r4,0		;Get first bcd digit
	andlw	0x0f		;Mask off other packed bcd digit'	
	addwf	temp,w		;Convert to ascii (add 0x30)
	call	LCD_Char	;Display it

dt2	swapf	r3,0		;Get 2nd bcd digit
	andlw	0x0f		;Mask off other packed bcd digit	
	addwf	temp,w		;Convert to ascii (add 0x30)
	call	LCD_Char	;Display it

dt3	movf	r3,0		;Get other bcd digit
	andlw	0x0f		;Mask off other packed bcd digit
	addwf	temp,w		;Convert to ascii (add 0x30)
	call	LCD_Char	;Display it

	
	swapf	r2,0		;Get next digit
	andlw	0x0f		;Mask off other packed bcd digit
	addwf	temp,w
	call	LCD_Char	;Display it
	
	;movlw	'.'		;Decimal point.
	;call	LCD_Char	

	movf	r2,0		;Get other bcd digit
	andlw	0x0f		;Mask off other packed bcd digit
	addwf	temp,w
	call	LCD_Char

	swapf	r1,0		;Get next digit
	andlw	0x0f		;Mask off other packed bcd digit
	addwf	temp,w
	call	LCD_Char	;Display it
	

	movf	r1,0		;Get other bcd digit
	andlw	0x0f
	addwf	temp,w
	call	LCD_Char
	
	;movlw	'.'		
	;call	LCD_Char		
	

	swapf	r0,0		;Get next digit
	andlw	0x0f		;Mask off other packed bcd digit
	addwf	temp,w
	call	LCD_Char	;Display it
	

	movf	r0,0		;Get other bcd digit
	andlw	0x0f
	addwf	temp,w
	call	LCD_Char	;Display last digit (1hz)
	
	movlw	' '		;Write MHz after freq.
	call	LCD_Char
	movlw	'M'
	call	LCD_Char
	movlw	'H'
	call	LCD_Char
	movlw	'z'
	call	LCD_Char
	
	return

    ; ****************************************************************
    ; * COUNTER FUNCTIONS                                            *
    ; * ----------------                                             *
    ; *   The following functions are defined:                       *
    ; *   CNTR_Clear  Clear counter                                  *
    ; *   CNTR_Copy   Copy counter to BCD in                         *
    ; *   CNTR_Inc    Increment counter                              *
    ; ****************************************************************	
	
CNTR_Clear
	movlw	0
	movwf	counterB0
	movwf	counterB1
	movwf	counterB2
	movwf	counterB3
	
	return 

CNTR_Copy
	movfw	counterB0
	movwf	byte0
	movfw	counterB1
	movwf	byte1
	movfw	counterB2
	movwf	byte2
	movfw	counterB3
	movwf	byte3
	
	return
	
CNTR_Inc
	
	incf	counterB0,1
	btfss	STATUS,Z
	goto	_incEnd

	incf	counterB1,1
	btfss	STATUS,Z
	goto	_incEnd

	incf	counterB2,1
	btfss	STATUS,Z
	goto	_incEnd

	incf	counterB3,1
	
_incEnd
	return 
	
    END








