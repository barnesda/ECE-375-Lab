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
.def	cmdr = r17				; Action code buffer register

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
.equ	Freeze =  0b11111000					; Freeze Action Code

.equ	BotAddy = 0b01110011	;Robot Addres Code

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
	ldi 	mpr, 0b11111111
	out	PORTD, mpr
	;USART1
		;Set baudrate at 2400bps
		ldi 	mpr, high($01A0)
		sts	UBRR1H, mpr
		ldi	mpr, low($01A0)
		out	UBRR1L, mpr
		;Enable transmitter
		ldi	mpr, (1<<TXEN1)
		out	UCSR1B, mpr
		;Set frame format: 8 data bits, 2 stop bits
		ldi	mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
		sts	UCSR1C, mpr
	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	in	mpr, PIND

	clr	cmdr
	
	; Check for inputs and load respective commands
	SBRS	mpr, 0
	ldi	cmdr, TurnR
	SBRS	mpr, 1
	ldi	cmdr, MovBck
	SBRS	mpr, 2
	ldi	cmdr, MovFwd
	SBRS	mpr, 3
	ldi	cmdr, TurnL
	SBRS	mpr, 4
	ldi	cmdr, Halt
	SBRS	mpr, 5
	ldi	cmdr, Freeze

	;If command to send, send it
	cpi	cmdr, 0
	breq	MAIN
	rcall	USART_Transmit

	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

USART_Transmit:
	sbis	UCSR1A, UDRE1	; Loop until UDR0 is empty
	rjmp	USART_Transmit
	ldi	mpr, BotAddy
	out	UDR1, mpr	; Move robot address to Transmit Data Buffer
USART_Transmit_Stage2:
	sbis	UCSR1A, UDRE1	; Loop until UDR0 is empty
	rjmp	USART_Transmit_Stage2
	out	UDR1, cmdr	; Move action code to Transmit Data Buffer
	ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
