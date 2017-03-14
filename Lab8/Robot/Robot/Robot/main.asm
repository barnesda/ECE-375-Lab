;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Jeffrey Noe
;*	   Date: Enter Date
;* * Robot address: 01110011
; ** 0x01A0 UBRR for baud rate
; ** $0024 UASRT0, Rx Complete
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	mpr2 = r20				; Multi-purpose Register
.def	waitcnt = r17			; Wait loop counter
.def	ilcnt = r18				; Inner loop counter
.def	olcnt = r19				; Outer loop counter
.def	execNextCommandCheck = r21		; Stores a 0 or 1 to execute the next command

.equ	WTime = 100				; Time to wait in wait loop


.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = 0b01110011	;(Enter your robot's address here (8 bits))
.equ	freeze = 0b01010101		; Send freeze command to other robots

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
;- Left whisker
;- Right Whisker
.org	$0002
		rcall HitRight
		reti
.org	$0004
		rcall HitLeft
		reti
;- USART receive
.org	$003C
		rcall usartReceive
		reti

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, high(RAMEND)
	out		sph, mpr
	ldi		mpr, low(RAMEND)
	out		spl, mpr

	;I/O Ports
	ldi		mpr, 0b00000010	;Pin 0 for input, pin 1 for output
	out		DDRE, mpr		

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


	;USART1
		ldi		mpr, (0<<UMSEL1)|(1<<USBS1)|(1<<UCSZ11)|(1<<UCSZ10)
		;ldi		mpr, 0b00001110; asynchronous, falling edge, 2 stop bits, no parity
		sts		ucsr1c, mpr

		ldi		mpr, (1<<RXCIE1)|(1<<TXCIE1)|(1<<RXEN1)|(1<<TXEN1)
		;ldi		mpr, 0b11011000
		sts		UCSR1B, mpr

		;Set baudrate at 2400bps
		ldi 	mpr, high($01A0)
		sts	UBRR0H, mpr
		ldi	mpr, high($01A0)
		out	UBRR0L, mpr

		;Enable receiver and enable receive interrupts

		;Set frame format: 8 data bits, 2 stop bits
		ldi	mpr, (0<<UMSEL0 | 1<<USBS0 | 1<<UCSZ01 | 1<<UCSZ00)
		sts	UCSR0C, mpr

		; Enable both receiver and transmitter, and receiv interrupt
		ldi mpr, (1<<RXEN0 | 1<<TXEN0 | RXCIE0)
		out UCSR0B, mpr

	;External Interrupts
		;Set the External Interrupt Mask
		; Set the Interrupt Sense Control to falling edge
		ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(0<<ISC20)|(1<<ISC21)|(0<<ISC30)|(1<<ISC31)
		sts EICRA, mpr

		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT2)	; PORTD pins 3 - 0
		out EIMSK, mpr

		ldi execNextCommandCheck, $00

		;Set the Interrupt Sense Control to falling edge detection
		sei
	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
HitRight:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		


		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		in		mpr, EIFR					; Load EIFR
		sbr		mpr, (1<<WskrR)|(1<<WskrL)	; Clear possible queued whisker interrupt flags
		out		EIFR, mpr					; Store modified values to EIFR

		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr

		ret

HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
	
		in		mpr, EIFR			; Load EIFR
		sbr		mpr, (1<<WskrR)|(1<<WskrL)	; Clear possible queued whisker interrupt flags
		out		EIFR, mpr			; Store modified values to EIFR

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret



;----------------------------------------------------------------
; Sub:	usartReceive
; Desc:	Handles actions when a uart signal has been received
;----------------------------------------------------------------
usartReceive:
	; Store PINB, PIND, and mpr
	push mpr
	in mpr, PINB
	push mpr
	in mpr, PIND
	push mpr


	lds mpr, UDR1

	cpi mpr, BotAddress
	breq setExecNextCommand

	cpi mpr, freeze
	breq Frozen

	; Now, assumed to be the next command from the remote
	

	; At the end of executing the next command, change execNextCommandCheck to $00 as next command is assumed to not be from the remote
	
	ldi execNextCommandCheck, $00

Frozen:
	; I'm frozen!
	rjmp skipToEnd


SetExecNextCommand:
	ldi execNextCommandCheck, $01
	rjmp skipToEnd



skipToEnd:
	
	; pop portD, PortB, and mpr off of the stack. 
	pop mpr
	out PORTD, mpr
	pop mpr
	out PORTB, mpr 

	; Clear interrupts so they don't que up
	ldi mpr, 0b00000011 ; Write logical one to INT0 and INT1
	out EIFR, mpr

	; Restore the state of the mpr
	pop mpr

	ret

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	waits for a specified amount of time
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
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************