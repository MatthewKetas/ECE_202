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
;; setting up gpio ports A and B and C


	LDR r0, =RCC_BASE				; starts at the address of the RCC_BASE MODULE
	LDR r1, [r0, #RCC_AHB2ENR]		; offsets to the address of the AHB2ENR reg which controlls the gpio clocks
	ORR r1, r1, #0x00000007			; mask to enable gpio ports A and B and C
	STR r1, [r0, #RCC_AHB2ENR]		; sends the bit mask back to the gpio memory


; GPIO B input (KEYPAD IN)

	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x0FC				;sets pins 1 2 3 to inputs
	STR r1, [r0, #GPIO_MODER]

; GPIO B input type  (KEYPAD IN)

	LDR r0, =GPIOB_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0x0FC;					set pins 1 2 3 and NO pull no pull down bc it is done externtally
	STR r1, [r0, #GPIO_PUPDR]

; GPIO C input (BLUE USER BUTTON)

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x0C000000				;sets pin 13 to input fix
	STR r1, [r0, #GPIO_MODER]

; GPIO C input type (BLUE USER BUTTON)

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0x0C000000				;sets pin 13 to no pull up no pull down
	STR r1, [r0, #GPIO_PUPDR]

; GPIO A OUTPUT 7632 DISP 7SEG ODR, 5 led on board

	LDR r0, =GPIOA_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x0000FCF0				; sets pins 7 6 5 3 2 to 0 to RST
	ORR r1, r1, #0x00005450				; sets pins to general purpose output mode
	STR r1, [r0, #GPIO_MODER]

; GPIO A output type OTYPER

	LDR r0, =GPIOA_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	BIC r1, r1, #0x000000EC			    ; will set pins to push/pull for 7632 7seg odr and 5 for led
	STR r1, [r0, #GPIO_OTYPER]

; GIPO A PINS output no pull up no pull down for and disp odr and green board LED

	LDR r0, =GPIOA_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0x0000FCF0
	STR r1, [r0, #GPIO_PUPDR]

	
; GIPO C PINS output (MOTOR DOOR) 11 10 9 8 (MOTOR WHEEL) 7654 (keypad ODR) 3210

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x00FFFFFF				    ;to reset pins
	ORR r1, r1, #0x00555555					;sets pins 11 10 9 8 76543210 to output	
	STR r1, [r0, #GPIO_MODER]
	
; GIPO C PINS output type

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_OTYPER]						
	BIC r1, r1, #0xFFF                      ;sets pins 11 10 9 8 7654 to push/pull and rst 3210
	ORR r1, r1, #0xF						;sets pins 3210 to open drain					
	STR r1, [r0, #GPIO_OTYPER]
	
; GIPO C PINS output no pull up no pull down
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	BIC r1, r1, #0xFF                    ;sets pins 11 10 9 8 7654 to pull up/pull down
	ORR r1, r1, #0x55					 ;sets pins 3210 to pull up check later
	STR r1, [r0, #GPIO_PUPDR]

; PC13 interrupt config fix later

; SETTING UP EXTERNAL INTERRUPT ; Using SYSCFG register to enable EXTI_13
	
	LDR r0, =SYSCFG_BASE ; Loading SYSCFG base address
	LDR r1, [r0, #SYSCFG_EXTICR4] ; Load EXTICR4 register to handle EXTI12-15 (we want 13)
	BIC r1, r1, #0x70 ; Clear bits 7-4 for EXTI_13 
	ORR r1, r1, #0x20 ; Setting Port C for GPIO
	STR r1, [r0, #SYSCFG_EXTICR4] ; Write back to EXTICR4

	; Enabling rising edge trigger for EXTI_13
	LDR r0, =EXTI_BASE ; Loading EXTI base address        
	LDR r1, [r0, #EXTI_RTSR1] ; Load rising trigger register onto r1      
	ORR r1, r1, #0x2000 ; Set bit 13 to 1 
	STR r1, [r0, #EXTI_RTSR1] ; Write back to rising trigger register

	; Enabling EXTI_13 interrupt -- IS THIS PROPER NOTATION (INFIX?)
	LDR r1, [r0, #EXTI_IMR1] ; Load the interrupt mask register
	ORR r1, r1, #0x2000 ; Turn on EXTI_13
	STR r1, [r0, #EXTI_IMR1] ; Write back to the interrupt mask register

	; Enabling EXTI_10 through EXTI_15 IRQ in NVIC
	LDR r0, =NVIC_ISER_BASE ; Loading the address of NVIC ISER1 base -- THIS DOES NOT EXIST!!!!!!!!!
	MOV r1, #0x100
	STR r1, [r0, #0x4] ; Enabling the interrupt for EXTI_10 through EXTI_15 

	; Setting NVIC priority for EXTI_13 to level 1
	LDR r0, =NVIC_IPR_BASE ; Loading the address of the NVIC IPR register
	LDR r1, [r0, #0xA0] ; Loading NVIC IPR for EXTI_10 through EXTI_15
	MOV r2, #0x10
	STRB r1, r2 ; Setting the priority of the interrupt
	
; End of GPIO Setup --------------------------------------------------------------------------------------------------------

; ----------------------------------------------------------------
; MAIN LOOP FUNCTION BELOW/description of registers 
; Beginning of constant loop
; A = 0, B = 1536, C = 3072 in cycles
; Register for Train Location Angle (Cycles)  r10
; Register for Door Angle (Cycle) r11
; Next State Register r9:  65, 66, 67 (A, B, C) ASCII values in HEX 
; Current State Register r8: 65, 66, 67 (A, B, C) ASCII values in HEX 

; ----------------------------------------------------------------
; Move to A

	MOV r3, #0 ;move 0 cycle (station A) for r3 to move to station A
	BL Move_Train
	MOV r9, #66 ;set next station to B

Main_Loop 
	;Move to B
	MOV r3, #1536 ;move 1536 cycle (station A) for r3 to move to station A
	BL Move_Train
	MOV r9, #67 ;set next station to B
	
	;Move to C
	MOV r3, #3072 ;move 0 cycle (station A) for r3 to move to station A
	BL Move_Train
	MOV r9, #66 ;set next station to B
	
	;Move to B
	MOV r3, #1536 ;move 0 cycle (station A) for r3 to move to station A
	BL Move_Train
	MOV r9, #65 ;set next station to B
	
	;Move to A
	MOV r3, #0 ;move 0 cycle (station A) for r3 to move to station A
	BL Move_Train
	MOV r9, #66 ;set next station to B
	
	B Main_Loop
	
Stop 
	B Stop 
	
	ENDP ; end of the main loop
		
; ----------------------------------------------------------------
;Branch to from main
Train_Move PROC ;uses r3 as the register to move to
	; 512 cycles (runs of Wheel_move) for 1 full rotation
moving_train_loop
	push{LR}
	
    CMP R10, R3               	; Compare R10 (current cycles of wheels and r3 desitnation cycle of wheels)
    BEQ moving_train_loop_end 	; If at station, break out of loop
	BGT move_train_left			;bigger angle than desired (past the desired station) 
	BLT move_train_right 		;smaller angle than desired (before the desired station)
	B moving_train_loop 		;loop again
	
move_train_right
	BL Wheel_moveRight
	B moving_train_loop
move_train_left 
	BL Wheel_moveLeft
	B moving_train_loop	
moving_train_loop_end 
	
	BL Open_door
	pop {LR}
	BX LR
	ENDP
		
		
;OPEN AND CLOSING DOORS (branch to from move)
; ----------------------------------------------------------------
Open_door PROC
	push{LR}
	
open_door_loop
	CMP r11, #128 ;128 cycles is roughly 90 degrees
	BEQ end_open_door
	BL Door_moveRight ;move towards 128 cycles
	B open_door_loop
end_open_door
	pop {LR}
	BX LR
	ENDP
		
;----------------------------------

Close_door PROC
	push{LR}

close_door_loop
	CMP r11, #0 
	BEQ end_close_door
	BL Door_moveLeft 	;move towards 0 angle 
	B close_door_loop
end_close_door
	pop {LR}
	BX LR
	ENDP
; ----------------------------------------------------------------
		
		
		
	
;	------- MOTOR processes

Wheel_moveRight PROC     ; Loading the GPIOC Output Register
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_ODR]
	PUSH{LR} ; Push the LR before all of the calls to the delay function

	
	; Step 1
	BIC r1, r1, #0xF0 ; Clear
	ORR r1, r1, #0x90 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
 	BL delay_motor
	
	; Step 2
	BIC r1, r1, #0xF0
	ORR r1, r1, #0x50
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 3
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0x60
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 4
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0xA0
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
	
	ADD R10, R10, #1 ;increments the cycle by 1 (right/cw 1)
 	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP
		
		
Wheel_moveLeft PROC
	; Loading the GPIOC Output Register
	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_ODR]
	PUSH{LR} ; Push the LR before all of the calls to the delay_motor function
	
	; Step 1 (4 CW)
	BIC r1, r1, #0xF0
	ORR r1, r1, #0xA0
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 2 (3 CW)
	BIC r1, r1, #0xF0 ; Clear
	ORR r1, r1, #0x60 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
	BL delay_motor
 
	; Step 3 (2 CW)
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0x50
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor

	; Step 4 (1 CW)	
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0x90
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
	
	SUB R10, R10, #1 ;decrements the cycle by 1 (left/ccw 1)
	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP

Door_moveRight PROC     
	LDR r0, =GPIOC_BASE    ; Loading the GPIOC Output Register
	LDR r1, [r0, #GPIO_ODR]
	PUSH{LR} ; Push the LR before all of the calls to the delay function

	
	; Step 1
	BIC r1, r1, #0xF0 ; Clear
	ORR r1, r1, #0x900 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
 	BL delay_motor
	
	; Step 2
	BIC r1, r1, #0xF0
	ORR r1, r1, #0x500
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 3
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0x600
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 4
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0xA00
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
	
	ADD R11, R11, #1 ;increments the cycle by 1 (right/cw 1)
 	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP
		
		
Door_moveLeft PROC
	LDR r0, =GPIOC_BASE     ; Loading the GPIOC Output Register
	LDR r1, [r0, #GPIO_ODR]
	PUSH{LR} ; Push the LR before all of the calls to the delay_motor function
	
	; Step 1 (4 CW)
	BIC r1, r1, #0xF0
	ORR r1, r1, #0xA00
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 2 (3 CW)
	BIC r1, r1, #0xF0 ; Clear
	ORR r1, r1, #0x600 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
	BL delay_motor
	
	; Step 3 (2 CW)
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0x500
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor

	; Step 4 (1 CW)	
	BIC r1, r1, #0xF0;
	ORR r1, r1, #0x900
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor

	SUB R11, R11, #1 ;decrements the cycle by 1 (left/ccw 1)
	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP
		

delay_motor_motor	PROC
	; Delay for software debouncing
	LDR	r2, =0x9AAA				;tune this for speeds maybe too slow
delayloop_motor
	SUBS	r2, #1
	BNE	delayloop_motor
	BX LR
	
	ENDP
		
					
	ALIGN			

	AREA myData, DATA, READWRITE
	ALIGN
char1	DCD	43
testByte DCD 0 ; THIS IS PURELY A TEST BYTE TO ENSURE THAT TERATERM IS WORKING PROPERLY
	END
