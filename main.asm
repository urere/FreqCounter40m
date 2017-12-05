#include "p16f882.inc"

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
PORTATRIS   equ 0xF0
LCD_D4	    equ	0
LCD_D5	    equ	1
LCD_D6	    equ	2
LCD_D7	    equ	3
LCD_DATA    equ	PORTA	    
	    
; PORT B 
; Bit 0	 OUT   LCD RS - Register Select
; Bit 1	 OUT   LCD EN - Enable
; Bit 2	 OUT   LED
; Bit 3	 IN   
; Bit 4	 IN   
; Bit 5	 IN   
; Bit 6	 IN   
; Bit 7	 IN   
PORTBTRIS   equ 0xF8
LCD_RS	    equ	0
LCD_EN	    equ	1
LCD_CONTROL equ	PORTB	    
LED	    equ	2	    
	    
; General Purpose Registers
delay1	    equ	0x20	; Delay routines
delay2	    equ	0x21	; Delay routines
delay3	    equ	0x22	; Delay routines
delay4	    equ	0x23	; Delay routines
	    
lcd_byte    equ	0x24	; Temp storage when sending a byte in 4 bit mode
lcd_tmpw    equ	0x25	; Temp w value when sending commands and data    

debug	    equ	0x26    
 
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

    ; Ports
	banksel	PORTA 
	clrf	PORTA
	banksel	PORTB 
	clrf	PORTB
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

    ; LCD	
	call	LCD_Init
	
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

	call	LCD_Line2
	movlw	' '
	call	LCD_Char
	movlw	' '
	call	LCD_Char
	movlw	' '
	call	LCD_Char
	movlw	' '
	call	LCD_Char
	movlw	' '
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
	

flash	bsf	PORTB,LED
	call	Delay1s
	bcf	PORTB,LED
	call	Delay1s
	goto	flash

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
	bcf	LCD_CONTROL,LCD_RS	
	bcf	LCD_CONTROL,LCD_EN
		
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
	movlw	0x28
	call	_LCD_WriteCommand
	call	Delay5ms
	
	call	LCD_Clear
	call	Delay5ms
				; Left to right
	movlw	0x28
	call	_LCD_WriteCommand
	call	Delay5ms

	call	LCD_Clear
				; Ready for data
	bsf	LCD_CONTROL,LCD_RS	
	
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
	bcf	LCD_CONTROL,LCD_RS	
	call	Delay10us
	movf	lcd_tmpw,0
	goto	_LCD_WriteByte

; Write DATA byte in w to LCD
_LCD_WriteData
	movwf	lcd_tmpw
	bsf	LCD_CONTROL,LCD_RS	
	call	Delay10us
	movf	lcd_tmpw,0
	goto	_LCD_WriteByte
	
; Write byte in w to LCD
_LCD_WriteByte
			    ; Upper 4 bits
	movwf	lcd_byte
	swapf	lcd_byte,0
	andlw	0x0f
	movwf	LCD_DATA	
	bsf	LCD_CONTROL,LCD_EN
	call	Delay10us
	bcf	LCD_CONTROL,LCD_EN	
	call	Delay10us

			    ; Lower 4 bits
	movf	lcd_byte,0
	andlw	0x0f
	movwf	LCD_DATA	
	bsf	LCD_CONTROL,LCD_EN
	call	Delay10us
	bcf	LCD_CONTROL,LCD_EN	
	call	Delay10us
	
	return

; Write nibble in w to LCD
_LCD_WriteNibble
			    ; Lower 4 bits only
	andlw	0x0f
	movwf	LCD_DATA	
	bsf	LCD_CONTROL,LCD_EN
	call	Delay10us
	bcf	LCD_CONTROL,LCD_EN	
	call	Delay10us
	
	return
	
    ; ****************************************************************
    ; * DELAY FUNCTIONS (8MHz Clock)                                 *
    ; * ---------------                                              *
    ; *   The following functions are defined:                       *
    ; *   Delay1s	1 Second                                     *
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
END








