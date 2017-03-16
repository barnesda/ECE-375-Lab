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
.def	freezeCount = r20		; Multi-purpose Register
.def	waitcnt = r17			; Wait loop counter
.def	ilcnt = r18				; Inner loop counter
.def	olcnt = r19				; Outer loop counter
.def	execNextCommandCheck = r21		; Stores a 0 or 1 to execute the next command
.def	portbSave = r22

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
	;ldi		mpr, 0b00000010	;Pin 0 for input, pin 1 for output
	;out		DDRE, mpr		

	; Initialize Port B for output
	ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
	out DDRB, mpr				; Output on B
	ldi mpr, (0<<EngEnL)|(0<<EngEnR)|(0<<EngDirR)|(0<<EngDirL)
	out PORTB, mpr				; All outputs low initially

	; Initialize Port D for input
	ldi mpr, (0<<WskrL)|(0<<WskrR)
	;ldi mpr, $00				; Port D all inputs
	out DDRD, mpr				; Input on all of D
	ldi mpr, (1<<WskrL)|(1<<WskrR)
	;ldi mpr, $FF				; All high initially
	out PORTD, mpr				; Using Pull-up resistors


	;USART1
		ldi		mpr, (0<<UMSEL1)|(1<<USBS1)|(1<<UCSZ11)|(1<<UCSZ10)
		;ldi		mpr, 0b00001110; asynchronous, falling edge, 2 stop bits, no parity
		sts		ucsr1c, mpr

		;ldi		mpr, (1<<RXCIE1)|(1<<TXCIE1)|(1<<RXEN1)|(1<<TXEN1)
		ldi			mpr, (1<<RXCIE1)|(1<<RXEN1)
		;ldi		mpr, 0b11011000
		sts		UCSR1B, mpr

		;Set baudrate at 2400bps
		ldi 	mpr, $01
		sts		UBRR1H, mpr
		ldi		mpr, $A0
		sts		UBRR1L, mpr

		;Enable receiver and enable receive interrupts

		;Set frame format: 8 data bits, 2 stop bits
		;ldi	mpr, (0<<UMSEL0 | 1<<USBS0 | 1<<UCSZ01 | 1<<UCSZ00)
		;sts	UCSR0C, mpr

		; Enable both receiver and transmitter, and receiv interrupt
		;ldi mpr, (1<<RXEN0 | 1<<TXEN0 | RXCIE0)
		;out UCSR0B, mpr

	;External Interrupts
		;Set the External Interrupt Mask
		; Set the Interrupt Sense Control to falling edge
		ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(0<<ISC20)|(1<<ISC21)|(0<<ISC30)|(1<<ISC31)
		sts EICRA, mpr

		ldi mpr, (1<<INT0)|(1<<INT1)
		out EIMSK, mpr

		; Explicitly stated, freezeCount is 0, the next command is assumed to not be from OUR remote
		ldi execNextCommandCheck, $00
		ldi freezeCount, $00

		;Set the Interrupt Sense Control to falling edge detection

		; Send move fwd command initially
		ldi mpr, MovFwd
		out PORTB, mpr
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
		in mpr, PINB
		push mpr

		


		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		mpr, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		mpr, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		in		mpr, EIFR					; Load EIFR
		sbr		mpr, (1<<WskrR)|(1<<WskrL)	; Clear possible queued whisker interrupt flags
		out		EIFR, mpr					; Store modified values to EIFR

		pop		mpr
		out		PORTB, mpr	; return to the previous command
		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr

		; Flush so interrupts aren't queued
		rcall USART_Flush

		ret

HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		in		mpr, PINB	; Save the output state to the stack
		push mpr

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		mpr, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		mpr, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
	
		in		mpr, EIFR			; Load EIFR
		sbr		mpr, (1<<WskrR)|(1<<WskrL)	; Clear possible queued whisker interrupt flags
		out		EIFR, mpr			; Store modified values to EIFR

		pop		mpr		; restore the command state
		out PORTB, mpr
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		; Flush so interrupts aren't queued
		rcall USART_Flush

		ret



;----------------------------------------------------------------
; Sub:	usartReceive
; Desc:	Handles actions when a uart signal has been received
;----------------------------------------------------------------
usartReceive:
	; Store mpr
	push mpr



	; Load the byte from the transmitter into mpr
	lds mpr, UDR1

	; Disable the receiver
	;ldi		mpr, (0<<RXCIE1)|(1<<TXCIE1)|(0<<RXEN1)|(1<<TXEN1)
	;sts		UCSR1B, mpr

	; is it the address to our bot?
	cpi mpr, BotAddress
	breq setExecNextCommand

	; else, is it the freeze command from another bot?
	cpi mpr, freeze
	breq Frozen

	; Now, assumed to be the next command from the remote
	ldi execNextCommandCheck, $00

	
	; Tell another bot to freeze?
	cpi mpr, 0b11111000
	breq sendFreezeCommand

	; Move Forward?
	cpi mpr, 0b10110000
	breq mvFwdCommand

	; Move Backward?
	cpi mpr, 0b10000000
	breq mvBckwdCommand

	; Halt?
	cpi mpr, 0b11001000
	breq HaltCommand

	; Turn Left?
	cpi mpr, 0b10010000
	breq turnLCommand

	; Turn right?
	cpi mpr, 0b10100000
	breq turnRCommand

	; At the end of executing the next command, change execNextCommandCheck to $00 as next command is assumed to not be from the remote
	ldi execNextCommandCheck, $00

	rjmp skipToEnd

Frozen:
	; I'm frozen!

	; Check if this is the third time I've been frozen
	inc freezeCount;
	cpi freezeCount, 3
	breq shutdown

	; push PORTB's output to the stack so we can return to the previous action (halt, mvFwd, turn left, turn right)
	 in mpr, PINB
	 push mpr
	 ;in portbSave, PINB

	; Disable the receiver
	;ldi		mpr, (0<<RXCIE1)|(1<<TXCIE1)|(0<<RXEN1)|(1<<TXEN1)
	;sts		UCSR1B, mpr
	;lds		mpr, UDR1
	;push	mpr		; UDR1 needs to be cleared according to Gurjeet to read the next command
	;ldi		mpr, $00
	;sts		UDR1, mpr

	; Send Halt command to PORTB
	ldi mpr, Halt
	out PORTB, mpr

	; Wait for 2.5 seconds twice
	ldi mpr, 250
	rcall Wait
	rcall Wait

	; return UDR1 to its previous state
	;pop		mpr
	;sts		UDR1, mpr

	; return PORTB to its previous state
	 pop mpr
	 out PORTB, mpr
	 ;out PORTB, portbSave

	; Enable the receiver
	;ldi		mpr, (1<<RXCIE1)|(1<<TXCIE1)|(1<<RXEN1)|(1<<TXEN1)
	;sts		UCSR1B, mpr
	ldi execNextCommandCheck, $00

	; Interrupts queued unless cleared
	rcall USART_Flush


	jmp skipToEnd

shutdown:
	; Do nothing!  I've been frozen three times!	
	ldi mpr, Halt
	out PORTB, mpr
	rjmp shutdown


SetExecNextCommand:
	ldi execNextCommandCheck, $01
	rjmp skipToEnd

sendFreezeCommand:

		; Disable the receiver
		ldi		mpr, (0<<RXCIE1)|(1<<TXCIE1)|(0<<RXEN1)|(1<<TXEN1)
		sts		UCSR1B, mpr

		; Send freeze command
		ldi mpr, freeze
		sts UDR1, mpr

		; Wait while transmitting to avoid freezing ourselves
		Transmitting:
			lds		mpr, UCSR1A
			sbrs	mpr, TXC1
			rjmp	Transmitting

		; Clear transmit flag
		lds mpr, UCSR1A
		cbr mpr, TXC1
		sts UCSR1A, mpr

		; Enable the receiver
		ldi		mpr, (1<<RXCIE1)|(1<<TXCIE1)|(1<<RXEN1)|(1<<TXEN1)
		sts		UCSR1B, mpr

		ldi execNextCommandCheck, $00

		rjmp skipToEnd

mvFwdCommand:
	ldi mpr, movFwd
	out PORTB, mpr

	rjmp skipToEnd

mvBckwdCommand:
	ldi mpr, MovBck
	out PORTB, mpr

	rjmp skipToEnd

HaltCommand:
	ldi mpr, Halt
	out PORTB, mpr

	rjmp skipToEnd

turnLCommand:
	ldi mpr, TurnL
	out PORTB, mpr

	rjmp skipToEnd

turnRCommand:
	ldi mpr, TurnR
	out PORTB, mpr

	rjmp skipToEnd

skipToEnd:
	
	; Clear interrupts so they don't que up
	ldi mpr, 0b00000011 ; Write logical one to INT0 and INT1
	out EIFR, mpr

	; Enable the receiver
	;ldi		mpr, (1<<RXCIE1)|(1<<TXCIE1)|(1<<RXEN1)|(1<<TXEN1)
	;sts		UCSR1B, mpr

	; Restore the state of the mpr
	pop mpr

	ret


USART_Flush:
	lds mpr, UCSR1A
	sbrs mpr, RXC1
	ret
	lds mpr, UDR1
	rjmp USART_Flush


	
;----------------------------------------------------------------
; Sub:	Wait
; Desc:	waits for a specified amount of time
;----------------------------------------------------------------
Wait:
		push	mpr			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		mpr		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		mpr			; Restore wait register
		ret					; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
