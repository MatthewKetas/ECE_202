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
	BL  System_Clock_Init ; Must enable the clock of the whole system first
	
	; Enabling the clock of GPIOB and GPIOC
	LDR r0, =RCC_BASE ; Loading the register RCC_Base
	LDR r1, [r0, #RCC_AHB2ENR] ; Loading the register with R0 for B enable
	ORR r1, r1, #0x00000006 ; Or command to turn on bits
	STR r1, [r0, #RCC_AHB2ENR] ; Storing the clock within register 1

	; Enable MODER output for GPIOB 7, 6, 3, 2 = CC
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_MODER]
	MOV r2, #0x0000F0F0
	BIC r1, r1, r2 ; Clear bits 15, 14, 13, 12, 7, 6, 5, and 4 for Pins 7, 6, 3, 2
	MOV r2, #0x00005050
	ORR r1, r1, r2 ; Setting output bits to 01 for output declarations
	STR r1, [r0, #GPIO_MODER]
	
	; Setting the output type within GPIOB OTYPER
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	BIC r1, r1, #0x000000CC ; Clearing bits 7, 6, 3, 2
	STR r1, [r0, #GPIO_OTYPER]
	
	
	; Enable MODER input for GPIOC 13 = C to clear
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #GPIO_MODER_MODER13 ; Clear bits 27, 26 for Pin 13
	STR r1, [r0, #GPIO_MODER]
	
	; Enabling no pull-up no pull-down for the pins
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #GPIO_PUPDR_PUPDR13 ; Setting the pin to no pull-up no pull-down
	STR r1, [r0, #GPIO_PUPDR]
	
	; Setting necessary counters for the display
	AND r12, r12, #0x00000000 ; Clearing all bits of r12 to 0
	ADD r12, r12, #0x00000001 ; Setting bit 0 to 1 of register 12
	AND r11, r11, #0x00000000 ; Resetting r11 for register counter
	
loop ; Beginning of constant loop
	; Must set up the delay loop
	AND r10, r10, #0x00000000 ; Setting all of the bits to 0
	LDR r4, =0x00A00000 ; Loading delay onto core register #4
	
delay_loop ; Loop to delay
	ADD r10, r10, #0x00000001 ; Adding one to register 10
	CMP r10, r4 ; Comparing to previously moved value
	BNE delay_loop	
	BEQ after_delay

			
after_delay ; After delaying get the input data and shift to turn on LEDs
if_nine
	; DISPLAY FIRST
	AND r7, r11, #0x0C ; reads the display value bits 3 and 2 from r11
	AND r3, r11, #0x03 ; reads the display value bits 1 and 0 from r11
	LDR r8, =GPIOB_BASE ; Loading base register
	LDR  r9, [r8, #GPIO_ODR] ; Offsetting the base register to access the ODR
	LSL r7, #4; moves bits 3 and 2 --> to 7 and 6
	LSL r3, #2; moves bits 1 and 0 --> to 3 and 2
	BIC  r9, r9, #0xCC ; Clear the bits in R9 before setting the new ones
	ORR  r9, r9, r7 ; Capture display bits from 3, 2
	ORR  r9, r9, r3 ; Capture display bits from 1, 0
	STR  r9, [r8, #GPIO_ODR] ; Storing values to register
	
	; BEGIN BRANCHING SEQUENCE
	CMP r11, #0x00000009 ; Check if the display register is already at 9
	BNE not_equal
	BEQ is_equal

not_equal
	ADD r11, r11, #0x00000001 ; Incrementing the display counter by 1 if it is not equal to 9
	B check_press; Branching to check for the button

is_equal	
	AND r11, r11, #0x00000000 ; Clearing bits back to 0 if the display counter is equal to 9	
	B check_press; Branching to check for the button
		
check_press
	LDR r8, =GPIOC_BASE ; Loading base
	LDR r9, [r8, #GPIO_IDR] ; read PC13
	TST r9, #0x2000 ; test bit 13
	BEQ button_press ; if bit 13 is off, then the button is pressed
	B   loop_end

		
button_press ; Defining what would happen during button press
	AND r11, r11, #0x00000000 ; Setting all of the bits to 0 for display counter
	B	 loop_end
		
loop_end
	; Finalizing loop code
	CMP r12, #0x00000000 ; Z flag will be 0, program will go back to the top of the loop
	BNE loop ; Go back to the top loop
	B stop ; Dead loop
		
	
stop 	B 		stop     		; dead loop & program hangs here

	ENDP
								

	AREA myData, DATA, READWRITE
	ALIGN

	END