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

	BL System_Clock_Init ; Initialize the clock at the start of the program
	
	;	Enable clocks for GPIOC, GPIOB//;	Enable clocks for GPIOA, GPIOB
	LDR r0, =RCC_BASE				; starts at the address of the RCC_BASE MODULE
	LDR r1, [r0, #RCC_AHB2ENR]		; offsets to the address of the AHB2ENR reg which controlls the gpio clocks
	ORR r1, r1, #0x6				;mask to enable gpio port A and B
	STR r1, [r0, #RCC_AHB2ENR]		; sends the bit mask back to the gpio memory
		
	; Set GPIOC pin 13 (blue button) as an input pin
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x0C000000;		sets pin 13 to input
	STR r1, [r0, #GPIO_MODER]		
	
	; Set GPIOC pin 13 to no pull up no pull down
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0x0C000000;		sets pin 13 to 
	STR r1, [r0, #GPIO_PUPDR]			
	
	; Set GPIOB pins 2, 3, 6, 7 as output pins
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_MODER]
	LDR r2, =0xF0F0 ; Immediate cannot be stored - must load into r2 and use that to BIC
	BIC r1, r1, r2;		sets 2, 3, 6, 7 to output
	LDR r2, =0x5050 ; Immediate cannot be stored - must load into r2 and use that to ORR
	ORR r1, r1, r2 ; ORR to set the pins to output
	STR r1, [r0, #GPIO_MODER]
	
	; Set Output Type for GPIOB
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	BIC r1, r1, #0xCC;		sets 2, 3, 6, 7 to push/pull
	STR r1, [r0, #GPIO_OTYPER]	
	
	; Set Output Resistors for BPIOB to no pull up no pull down
    LDR r0, =GPIOB_BASE
    LDR r1, [r0, #GPIO_PUPDR]
    LDR r2, =0xF0F0 ; Immediate cannot be stored - must load into r2 and use that to BIC
	BIC r1, r1, r2;		sets 2, 3, 6, 7 to pull up/pull down
    STR r1, [r0, #GPIO_PUPDR]
	

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;; YOUR CODE GOES HERE ;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	
check_loop
	BL delay ; First debounce before checking for button
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_IDR]
	BIC r1, r1, #0xFFFFDFFF ; Isolate pin 13
	CMP r1, #0x2000 ; Checking to see if the button is active low - if matches with this button is not pressed
	BEQ check_loop ; Keep checking for a button press
	MOVNE r4, #1650 ; For loop index 
	BNE swiper_loop ; Button was pressed
	
	;starts swiping and checks when the swipping function is done
swiper_loop
	CMP r4, #0
	BEQ check_loop
	SUB r4, r4, #1
	LDR r5, =825
	CMP r4, r5
	BLE move_right
	BGT move_left
move_left
	BL delay
	BL moveLeft
	B swiper_loop
move_right
	BL delay
	BL moveRight
	B swiper_loop
	
	ENDP
	

	
	; If button is pressed at the end of the process - just go back to swiper loop - if not go back to check loop
			
	
moveRight PROC
	; Loading the GPIOB Output Register
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_ODR]
	PUSH{LR} ; Push the LR before all of the calls to the delay function

	
	; Step 1
	BIC r1, r1, #0xFF ; Clear
	ORR r1, r1, #0x84 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
 	BL delay
	
	; Step 2
	BIC r1, r1, #0xFF
	ORR r1, r1, #0x44
	STR r1, [r0, #GPIO_ODR]
	BL delay
 
	; Step 3
	BIC r1, r1, #0xFF;
	ORR r1, r1, #0x48
	STR r1, [r0, #GPIO_ODR]
	BL delay
 
	; Step 4
	BIC r1, r1, #0xFF;
	ORR r1, r1, #0x88
	STR r1, [r0, #GPIO_ODR]
	BL delay
 
 	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP
		
		
moveLeft PROC
	; Loading the GPIOB Output Register
	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_ODR]
	PUSH{LR} ; Push the LR before all of the calls to the delay function
	
	; Step 1 (3 CW)
	BIC r1, r1, #0xFF
	ORR r1, r1, #0x48
	STR r1, [r0, #GPIO_ODR]
	BL delay
 
	; Step 2 (4 CW)
	BIC r1, r1, #0xFF ; Clear
	ORR r1, r1, #0x88 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
	BL delay
 
	; Step 3 (1 CW)
	BIC r1, r1, #0xFF;
	ORR r1, r1, #0x84
	STR r1, [r0, #GPIO_ODR]
	BL delay

	; Step 4 (2 CW)	
	BIC r1, r1, #0xFF;
	ORR r1, r1, #0x44
	STR r1, [r0, #GPIO_ODR]
	BL delay

	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP
		

delay	PROC
	; Delay for software debouncing
	LDR	r2, =0x9999				;tune this for speeds maybe too slow
delayloop
	SUBS	r2, #1
	BNE	delayloop
	BX LR
	
	ENDP
	
	
	
	
	ALIGN			

	AREA myData, DATA, READWRITE
	ALIGN
; Replace ECE1770 with your last name
str DCB "ECE1770",0
	END
