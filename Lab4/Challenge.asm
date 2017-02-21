;***********************************************************
;*
;*	Challenge.asm
;*
;*	Displays Your Name and scrolls it across the screen
;*
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Danny Barnes
;*	   Date: February 9, 2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
.def	counter = r23			; Counter for loop
.def	temp = r24
.def	waitcnt = r25				; Wait Loop Counter
.def	ilcnt = r26				; Inner Loop Counter
.def	olcnt = r27				; Outer Loop Counter

.equ	WTime = 20				; Time to wait in wait loop

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

		ldi counter, 15
		ldi YL, low(SRAM_START + 15)
		ldi YH, high(SRAM_START + 15)
		ld temp, Y
		sbiw YH:YL, 1

LOOP2:		ld mpr, Y+
		st Y, mpr
		sbiw YH:YL, 2
		dec counter
		brne LOOP2

		adiw YH:YL, 1
		st Y, temp

		ldi counter, 15
		ldi YL, low(SRAM_START + 31)
		ldi YH, high(SRAM_START + 31)
		ld temp, Y
		sbiw YH:YL, 1

LOOP3:		ld mpr, Y+
		st Y, mpr
		sbiw YH:YL, 2
		dec counter
		brne LOOP3

		adiw YH:YL, 1
		st Y, temp	

		ldi	waitcnt, WTime		; Wait for 1 second
		rcall	WaitFunc		; Call wait function

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

WaitFunc:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

PLoop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	PLoop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

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
