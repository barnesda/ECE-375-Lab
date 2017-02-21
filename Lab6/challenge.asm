;***********************************************************
;*
;*	InturruptBumpBot.asm
;*
;*	Bumpbot with interrupts instead of polling
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Danny Barnes
;*	   Date: February 23, 2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	lasthit = r20				; Bumper last side hit
.def	hitctr = r21				; Bumper hit counter

.equ	WTime = 100				; Time to wait in wait loop
.equ	WTimeL = 200				; Alternate time to wait in wait loop (longer)

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

.org	$0002	;Right Whisker Hit
		rcall	HitRight		; Call Hit Right function
		reti				; Return from interrupt

.org	$0004	;Left Whisker Hit		; Call Hit Left function
		rcall HitLeft			; Return from interrupt
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi mpr, low(RAMEND)			; Low byte init
		out SPL, mpr
		ldi mpr, high(RAMEND)			; High byte init
		out SPH, mpr
		
		; Initialize Port B for output
		ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
		out DDRB, mpr				; Output on B
		ldi mpr, (0<<EngEnL)|(0<<EngEnR)|(0<<EngDirR)|(0<<EngDirL)
		out PORTB, mpr				; All outputs low initially
		
		; Initialize Port D for input
		ldi mpr, (0<<WskrL)|(0<<WskrR)
		out DDRD, mpr				; Input on D
		ldi mpr, (1<<WskrL)|(1<<WskrR)
		out PORTD, mpr				; Using Pull-up resistors

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge 
		ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
		sts EICRA, mpr

		; Configure the External Interrupt Mask
		ldi mpr, (1<<INT0)|(1<<INT1)
		out EIMSK, mpr

		;Initialize Bumper History
		ldi lasthit, $00
		ldi hitctr, $00

		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program


		; Move Forward	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Clear counter if not an alternating hit
		sbrc		lasthit, WskrR	; If this is second right hit in a row,
		clr		hitctr ; Clear the hit counter

		; Increase the hit counter
		inc		hitctr	

		; Check for stuck in corner (5 alternating hits)
		cpi	hitctr, 5		; Compare hit counter to 5
		brne	HitRightCont		; If not equal, continue to normal behavior
		rcall	CornerStuck		; Else, call stuck in corner function
		rjmp	HitRightEnd 		; Then jump to the exit code

HitRightCont:	; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		sbrc		lasthit, WskrR	; Skip next instruction unless second right hit in a row
		ldi 		waitcnt, WTimeL ; Wait for 2 seconds instead
		rcall	Wait			; Call wait function

HitRightEnd:	in		mpr, EIFR			; Load EIFR
		sbr		mpr, (1<<WskrR)|(1<<WskrL)	; Clear possible queued whisker interrupt flags
		out		EIFR, mpr			; Store modified values to EIFR

		ldi		lasthit, (1<<WskrR)|(0<<WskrL)	; Store hit information for later use

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Clear counter if not an alternating hit
		sbrc		lasthit, WskrL	; If this is second left hit in a row,
		clr		hitctr ; Clear the hit counter

		; Increase the hit counter
		inc		hitctr	

		; Check for stuck in corner (5 alternating hits)
		cpi	hitctr, 5		; Compare hit counter to 5
		brne	HitLeftCont		; If not equal, continue to normal behavior
		rcall	CornerStuck		; Else, call stuck in corner function
		rjmp	HitLeftEnd 		; Then jump to the exit code

HitLeftCont:	; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		sbrc		lasthit, WskrL	; Skip next instruction unless second right hit in a row
		ldi 		waitcnt, WTimeL ; Wait for 2 seconds instead
		rcall	Wait			; Call wait function
	
HitLeftEnd:	in		mpr, EIFR			; Load EIFR
		sbr		mpr, (1<<WskrR)|(1<<WskrL)	; Clear possible queued whisker interrupt flags
		out		EIFR, mpr			; Store modified values to EIFR

		ldi		lasthit, (0<<WskrR)|(1<<WskrL)	; Store hit information for later use

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	CornerStuck
; Desc:	Handles functionality of the TekBot when stuck in a corner
;----------------------------------------------------------------
CornerStuck:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a few seconds (lets say 4) to turn around
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTimeL	; Wait for 2 second
		rcall	Wait			; Call wait function
		rcall	Wait			; Call wait function

		clr		hitctr		; Reset the hit counter back to 0	

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program

