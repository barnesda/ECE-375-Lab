;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Danny Barnes
;*	   Date: 	
;*	address: b01110011
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code

.equ	BotAddy = b01110011	;Robot Addres Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi 	mpr, high(RAMEND) 
	out 	SPH, mpr 
	ldi 	mpr, low(RAMEND) 
	out 	SPL, mpr 
	;I/O Ports
	ldi 	mpr, 0b00000000
	out	DDRD, mpr
	ldi 	mpr, 0b00011111
	out	PORTD, mpr
	;USART1
		;Set baudrate at 2400bps
		ldi 	mpr, high($01A0)
		sts	UBRR0H, mpr
		ldi	mpr, high($01A0)
		out	UBRR0L, mpr
		;Enable transmitter
		ldi	mpr, (1<<TXEN0)
		out	UCSR0B, mpr
		;Set frame format: 8 data bits, 2 stop bits
		ldi	mpr, (0<<UMSEL0 | 1<<USBS0 | 1<<UCSZ01 | 1<<UCSZ00)
		sts	UCSR0C, mpr
	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	in	mpr, PIND

	clr	r17
	
	SBRS	mpr, 0
	ldi	r17, TurnR
	SBRS	mpr, 1
	ldi	r17, MovBck
	SBRS	mpr, 2
	ldi	r17, MovFwd
	SBRS	mpr, 3
	ldi	r17, TurnL
	SBRS	mpr, 4
	ldi	r17, Halt

	;TODO: add call to transmit if r17 nonempty

	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

USART_Transmit:
	sbis	UCSR0A, UDRE0	; Loop until UDR0 is empty
	rjmp	USART_Transmit
	ldi	mpr, BotAddy
	out	UDR0, mpr	; Move robot address to Transmit Data Buffer
USART_Transmit_Stage2:
	sbis	UCSR0A, UDRE0	; Loop until UDR0 is empty
	rjmp	USART_Transmit_Stage2
	out	UDR0, r17	; Move action code to Transmit Data Buffer
	ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
