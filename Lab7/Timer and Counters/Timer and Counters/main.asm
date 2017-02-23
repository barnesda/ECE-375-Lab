;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

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

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer

		; Configure I/O ports

		; Configure External Interrupts, if needed

		; Configure 8-bit Timer/Counters

								; no prescaling

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)

		; Set initial speed, display on Port B pins 3:0

		; Enable global interrupts (if any are used)

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
FUNC:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program