;***********************************************************
;*
;*	Counters/Timers
;*
;*	Uses counters and timers to increase and decrease the power to two outputs (Pulse Width Modulation)
;*	which can control the speed of motors connected to the output pins
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	Author:			Jeffrey Noe
;*	Lab Partner:	Daniel Barnes
;*	Date:			2/24/2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def resetFlag = r23			; Flag variable to reset flag


.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit
.equ	ButtonConfig = 0b11110000	; 7:4 as outputs, 3:0 as inputs
.equ	PortDResistorConfig = 0b00001111	;7:4 has no pull-up resistors, 3:0 uses pull-up resistors
.equ	movFwd = (1<<EngDirR|1<<EngDirL)	; Configure bits as move forward command
.equ	toggleSpeed = 17					; Used to increment/decrement speed


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed
		; Button-layout should be: Stop : MaxSpeed : DecSpeed : IncSpeed
.org	$0002					; Increase speed requested
		rcall IncSpeed			; Call increase speed function
		reti					; Return from increase speed function

.org	$0004					; Decrease speed requested
		rcall DecSpeed			; Call decrease speed function
		reti					; Return from decrease speed function

.org	$0006					; Max Speed Requested
		rcall MaxSpeed			; Call max speed function
		reti					; Return from max speed function

.org	$0008					; Stop Requested
		rcall Stop				; Call stop function
		reti

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi mpr, low(RAMEND)			; Low byte init
		out SPL, mpr
		ldi mpr, high(RAMEND)			; High byte init
		out SPH, mpr

		; Configure I/O ports
		; Configure Port B
		ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)|0b00001111
		out DDRB, mpr				; Output on B
		ldi mpr, (0<<EngEnL)|(0<<EngEnR)|(0<<EngDirR)|(0<<EngDirL)
		out PORTB, mpr				; All outputs low initially

		;Configure Port D
		ldi mpr, buttonConfig			; Load button configuration for Port D
		out DDRD, mpr					; D 7:4 outputs, D 3:0 inputs
		ldi mpr, PortDResistorConfig	; Load pull-up resistor configuration
		out PORTD, mpr					; Pull-up resistors on buttons 3:0

		; Configure External Interrupts, if needed
		; Set the Interrupt Sense Control to falling edge
		ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(0<<ISC20)|(1<<ISC21)|(0<<ISC30)|(1<<ISC31)
		sts EICRA, mpr

		; Configure the External Interrupt Mask
		ldi mpr, (1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)	; PORTD pins 3 - 0
		out EIMSK, mpr

		; Configure 8-bit Timer/Counters
		; Configure timer/counter 0
		;SBI DDRB, PB4			; Set bit 4 of port B (OCO) for output
		LDI mpr, 0b01101111		; Activate fast PWN mode with toggle
		OUT TCCR0, mpr			; (non-inverting) & set prescaler to 1024

								; no prescaling

		; Configure timer/counter 2
		;SBI DDRB, PB4			; Set bit 4 of port B (OCO) for output
		LDI mpr, 0b01101101		; Activate fast PWN mode with toggle
		OUT TCCR2, mpr			; (non-inverting) & set prescaler to 1024 (last three bits 101 for TCCR2 and 111 for TCCR0)


		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)
		;LDI mpr, movFwd
		;OUT PORTB, mpr

		ldi r17, toggleSpeed
		ldi resetFlag, 0b00001111

		; Set initial speed, display on Port B pins 3:0

		; Enable global interrupts (if any are used)
		sei
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; poll Port D pushbuttons (if needed)

								; if pressed, adjust speed
								; also, adjust speed indication

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------

;-----------------------------------------------------------
; Func:	IncSpeed
; Desc:	Increments the speed to the motors by 1
;-----------------------------------------------------------
IncSpeed:

		; If needed, save variables by pushing to the stack


		; Check if we are already at max speed
		in mpr, OCR0
		cpi mpr, 255
		breq SkipInc

		; Else, increment the speed and write to OCR0
		add mpr, r17
		out OCR0, mpr



SkipInc: ; Value is already at max speed
		; Restore any saved variables by popping from stack

		out EIFR, resetFlag
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	DecSpeed
; Desc:	Decrements the speed to the motors by 1
;-----------------------------------------------------------
DecSpeed:

		; If needed, save variables by pushing to the stack

		; Check if we are already at min speed
		in mpr, OCR0
		cpi mpr, 0
		breq SkipDec

		; Else, decrement the speed and write to OCR0
		sub mpr, r17
		out OCR0, mpr

SkipDec: ; Already at min speed

		; Restore any saved variables by popping from stack
		out EIFR, resetFlag
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	MaxSpeed
; Desc:	Sends max speed to motors
;-----------------------------------------------------------
MaxSpeed:

		; If needed, save variables by pushing to the stack

		; Execute the function here

		in mpr, OCR0
		ldi mpr, 255
		out OCR0, mpr

		; Restore any saved variables by popping from stack

		out EIFR, resetFlag; Clear flags
		ret						; End a function with RET

;-----------------------------------------------------------
; Func:	Stop
; Desc:	Sends stop command to the motors (writes logical 0 to output pins)
;-----------------------------------------------------------
Stop:

		; If needed, save variables by pushing to the stack

		; Execute the function here
		in mpr, OCR0
		ldi mpr, 0
		out OCR0, mpr

		; Restore any saved variables by popping from stack

		out EIFR, resetFlag ; Clear flags
		ret						; End a function with RET



;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"
; Comments below the 'include'
		; There are no additional file includes for this program
