;***********************************************************
;*
;*	HelloWorld.asm
;*
;*	Displays Your Name and 
;*
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Danny Barnes and Aravind Parasurama
;*	   Date: Oct. 19, 2016
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
.def	counter = r23			; Counter for loop

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi mpr, low(RAMEND)
		out SPL, mpr
		ldi mpr, high(RAMEND)
		out SPH, mpr
		
		; Initialize LCD Display
		rcall LCDInit
		
		; Move strings from Program Memory to Data Memory
		ldi ZL, low(STRING_BEG<<1)
		ldi ZH, high(STRING_BEG<<1)
		ldi YL, low(SRAM_START)
		ldi YH, high(SRAM_START)
				ldi counter, 32


LOOP:		LPM mpr, Z+
		ST Y+, mpr
		dec counter
		brne LOOP


		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		rcall	LCDWrite


		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB		"Danny Barnes    Hello World!    "		; Declaring data in ProgMem
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
