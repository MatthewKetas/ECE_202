;******************** (C) Yifeng ZHU *******************************************
; @file    main.s
; @author  Yifeng Zhu
; @date    May-17-2015
; @note
;           This code is for the book "Embedded Systems with ARM Cortex-M 
;           Microcontrollers in Assembly Language and C, Yifeng Zhu, 
;           ISBN-13: 978-0982692639, ISBN-10: 0982692633
; @attension
;           This code is provided for education purpose. The author shall not be 
;           held liable for any direct, indirect or consequential damages, for any 
;           reason whatever. More information can be found from book website: 
;           http:;www.eece.maine.edu/~zhu/book
;*******************************************************************************


	INCLUDE core_cm4_constants.s		; Load Constant Definitions
	INCLUDE stm32l476xx_constants.s      

	IMPORT 	System_Clock_Init
	IMPORT 	UART2_Init
	IMPORT	USART2_Write
	
	AREA    main, CODE, READONLY
	EXPORT	__main				; make __main visible to linker
	ENTRY			
				
__main	PROC
	
	BL System_Clock_Init ; Clock is initialized here - does not have to be done below
	BL UART2_Init



;;;;;;;;;;;; YOUR CODE GOES HERE	;;;;;;;;;;;;;;;;;;;
;; setting up gpio ports B and C


	LDR r0, =RCC_BASE				; starts at the address of the RCC_BASE MODULE
	LDR r1, [r0, #RCC_AHB2ENR]		; offsets to the address of the AHB2ENR reg which controlls the gpio clocks
	ORR r1, r1, #0x00000006			;mask to enable gpio port B and C
	STR r1, [r0, #RCC_AHB2ENR]		; sends the bit mask back to the gpio memory
	
; GPIO B input

	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x0FC;			sets pins 1 2 3 to input
	STR r1, [r0, #GPIO_MODER]
	
; input type B

	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0x0FC;					set pins 1 2 3 and NO pull no pull down bc it is done externtally
	STR r1, [r0, #GPIO_PUPDR]
	
; GIPO C PINS output

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0xFF
	ORR r1, r1, #0x55;					sets pins 0123 to output	
	STR r1, [r0, #GPIO_MODER]
	
; output type

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	AND r1, #0x0;				rst - TEST TO SET TO PUSH PULL
	ORR r1, r1, #0xF; 				sets pins 0123 to open drain					
	STR r1, [r0, #GPIO_OTYPER]
	
; output no pull up no pull down
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0xFF
	ORR r1, r1, #0x55
	STR r1, [r0, #GPIO_PUPDR]
	
; End of GPIO Setup --------------------------------------------------------------------------------------------------------

loop ; Beginning of constant loop

	; Pull all rows low
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_ODR] 
	AND r1, r1, #0xFFFFFFF0 ; Set all row pins to low
	STR r1, [r0, #GPIO_ODR]
	
	
	; Invoking delay function
	BL delay
	
	
	; Scan columns to find if button is pressed - r0 has result
	BL delay
	BL checkCols
	CMP r0, #0xE
	BEQ loop ; Go back to the start of the loop and check again for a pressed button
	MOV r5, r0 ; Move the result of the function into r5
	
	
	; Cycling through rows to determine the letter being pressed
	AND r6, r6, #0x0 ; Clearing r6
	MOV r6, #0x8 ; Moving hex pin tester to r6 for loop control and masking
rowLoop
	CMP r6, #0x0
	BEQ afterLoop ; Ensures end of for loop
	MOV r0, r6 ; Move the value from r6 to r0 so that we follow calling convention
	BL checkRow
	CMP r0, #1 ; checkRow will be 1 if true
	BEQ afterLoop ;replaced the positiveTest, branches to afterLoop
	LSR r6, r6, #1 ; LSL the mask and counter over by 1
	BNE rowLoop
afterLoop
	; NOW COL IS IN R5 ROW IS IN R6 WITH BOTH ACTIVE LOW
	
springLoop ;checks to see if a button is unpressed or if another button is pressed.
	BL delay
	BL checkCols
	CMP r0, r5
	BNE coltorow ;means the button was unpressed so we move to display it
	
	B springLoop	;the button is still being pressed.


	
coltorow
	EOR R5, #0xE;  if r5 holds col sets to inverted ex 011-> 100 MUST DO THIS FIRST
	
	CMP R6, #0x1
	BEQ row0
	CMP R6, #0x2
	BEQ row1
	CMP R6, #0x4
	BEQ row2
	CMP R6, #0x8
	BEQ row3
	
row0
	CMP R5, #0x8
	MOVEQ R5, #51; '3'
	BEQ displaykey
	CMP R5, #0X4
	MOVEQ R5, #50; '2'
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #49; '1'	
	BEQ displaykey

row1
	CMP R5, #0x8
	MOVEQ R5, #54; '6'
	BEQ displaykey
	CMP R5, #0X4
	MOVEQ R5, #53; '5'
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #52; '4'
	BEQ displaykey

row2
	CMP R5, #0x8
	MOVEQ R5, #57; '9'
	BEQ displaykey
	CMP R5, #0X4
	MOVEQ R5, #56; '8'
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #55; '7'
	BEQ displaykey

row3
	CMP R5, #0x8
	MOVEQ R5, #35; '#'
	BEQ displaykey
	CMP R5, #0X4
	MOVEQ R5, #48; '0'
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #42; '*'
	BEQ displaykey
	
		
		
		
displaykey
	LDR	r0, =char1
	STR	r5, [r0]
	MOV r1, #1    ; Second argument
	BL USART2_Write
	B loop 		; after displaying a key returns to start
	ENDP		

			
	

delay	PROC
	; Delay for software debouncing
	LDR	r2, =0x9999
delayloop
	SUBS	r2, #1
	BNE	delayloop
	BX LR
	
	ENDP



; RETURNS Pin 1-3 as HIGH depending on voltage
checkCols PROC
	; Checking columns of the keypad
	LDR r1, =GPIOB_BASE
	LDR r2, [r1, #GPIO_IDR]
	AND r2, r2, #0xE ; Mask everything but bits 1-3
	MOV r0, r2
	BX LR 
	
	ENDP


; RETURNS 1 if the row test is positive and 0 if it is negative
checkRow PROC
	; ROW 0 SET
	LDR r1, =GPIOC_BASE
	LDR r2, [r1, #GPIO_ODR] 
	AND r2, r2, #0xFFFFFFF0 ; Clearing the last 4 bits of the register
	EOR r0, r0, #0xF ; This puts r0 with proper calling convention and toggles pins i.e. 0111
	ORR r2, r2, r0 ; This copies the last 4 bits of r0 into r2
	STR r2, [r1, #GPIO_ODR] ; Assuming non-inverted - this is finished
	
	; DELAY 1
	PUSH{LR}
	BL delay
	POP{LR}
	
	
	; TEST COL AGAIN
	PUSH{LR}
	BL checkCols
	POP{LR}
	MOV r3, r0	;value of test row is in r3 now
	CMP r3, #0xE ; Check if all cols are high with the new input
	MOVEQ r0, #0 ; Return 0 if no button is pressed
	MOVNE r0, #1 ; Return 1 for a button is being pressed 
	
	BX LR
	ENDP
		
					
	ALIGN			

	AREA myData, DATA, READWRITE
	ALIGN

char1	DCD	43
testByte DCD 0 ; THIS IS PURELY A TEST BYTE TO ENSURE THAT TERATERM IS WORKING PROPERLY
	END