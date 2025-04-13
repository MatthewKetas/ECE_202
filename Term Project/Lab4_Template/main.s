
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
	LDR r2, =0x00FF0C00
	BIC r1, r1, r2				; sets pins 11 10 9 8 5 to 0 to RST
	LDR r2, =0x00550400
	ORR r1, r1, r2			; sets pins to general purpose output mode
	STR r1, [r0, #GPIO_MODER]

; GPIO A output type OTYPER

	LDR r0, =GPIOA_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	BIC r1, r1, #0xF20	             ; will set pins to push/pull for 7seg and led board
	STR r1, [r0, #GPIO_OTYPER]

; GIPO A PINS output no pull up no pull down for and disp odr and green board LED

	LDR r0, =GPIOA_BASE
	LDR r1, [r0, #GPIO_PUPDR]
	LDR r2, =0x00FF0C00
	BIC r1, r1, r2
	STR r1, [r0, #GPIO_PUPDR]

	
; GIPO C PINS output (MOTOR DOOR) 11 10 9 8 (MOTOR WHEEL) 7654 (keypad ODR) 3210

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_MODER]
	BIC r1, r1, #0x00FFFFFF				    ;to reset pins
	LDR r2, =0x00555555
	ORR r1, r1, r2					;sets pins 11 10 9 8 76543210 to output	
	STR r1, [r0, #GPIO_MODER]
	
; GIPO C PINS output type

	LDR r0, =GPIOC_BASE
	LDR r1, [r0, #GPIO_OTYPER]
	LDR r2, =0xFFF
	BIC r1, r1, r2                      ;sets pins 11 10 9 8 7654 to push/pull and rst 3210
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
	
	        ; GOOD
			
	LDR r0, =RCC_BASE
	LDR r1, [r0, #RCC_APB2ENR]
	ORR r1, r1, #RCC_APB2ENR_SYSCFGEN
	STR r1, [r0, #RCC_APB2ENR]
	
	LDR r0, =0x40010014
	LDR r1, [r0]
	BIC r1, r1, #0xF0
	ORR r1, r1, #0x20
	STR r1, [r0]

    

        ; GOOD STEP 1:

    ; Enabling EXTI_13 interrupt -- IS THIS PROPER NOTATION (INFIX?)
	LDR r0, =EXTI_BASE ; Loading EXTI base address 
    LDR r1, [r0, #EXTI_IMR1] ; Load the interrupt mask register
    ORR r1, r1, #0x2000 ; Turn on EXTI_13
    STR r1, [r0, #EXTI_IMR1] ; Write back to the interrupt mask register

        ; GOOD STEP 2:

    ; Enabling rising edge trigger for EXTI_13
    LDR r0, =EXTI_BASE ; Loading EXTI base address        
    LDR r1, [r0, #EXTI_RTSR1] ; Load rising trigger register onto r1      
    ORR r1, r1, #0x2000 ; Set bit 13 to 1 
    STR r1, [r0, #EXTI_RTSR1] ; Write back to rising trigger register

       
    ; GOOD STEP 3: may need to find write permission and check EXTI_in table spot 40
	LDR r0, =0xE000E104;  base NVIC reg block  NVIC_ISER1 
	MOV r1, #0x100;   set bit 8 to enable EXTI lines 15:10
	STR r1, [r0];

    ; Setting NVIC priority for EXTI_13 to 0 highest priority for non sys
    
  ; LDR r1, [r0, #0x328]; NVIC_IPR10
  ; BIC r1, r1, #0xF0; set bits [7:4] to 0 for prioirty 0
  ; STR r1, [r0, #0x328];
	
; End of GPIO Setup --------------------------------------------------------------------------------------------------------

	
	MOV r11, #0 ;intilize the door to 0 angle
	
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
Move_Train PROC ;uses r3 as the register to move to
	; 512 cycles (runs of Wheel_move) for 1 full rotation
	push {LR}
	BL Close_door
	
moving_train_loop
	
	
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
	BIC r1, r1, #0xF00 ; Clear
	ORR r1, r1, #0x900 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
 	BL delay_motor
	
	; Step 2
	BIC r1, r1, #0xF00
	ORR r1, r1, #0x500
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 3
	BIC r1, r1, #0xF00;
	ORR r1, r1, #0x600
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 4
	BIC r1, r1, #0xF00;
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
	BIC r1, r1, #0xF00
	ORR r1, r1, #0xA00
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor
 
	; Step 2 (3 CW)
	BIC r1, r1, #0xF00 ; Clear
	ORR r1, r1, #0x600 ; Set
	STR r1, [r0, #GPIO_ODR] ; Store - then CYCLE REPEATS
	BL delay_motor
	
	; Step 3 (2 CW)
	BIC r1, r1, #0xF00;
	ORR r1, r1, #0x500
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor

	; Step 4 (1 CW)	
	BIC r1, r1, #0xF00;
	ORR r1, r1, #0x900
	STR r1, [r0, #GPIO_ODR]
	BL delay_motor

	SUB R11, R11, #1 ;decrements the cycle by 1 (left/ccw 1)
	POP{LR} ; Pop the pushed address before returning to the branch 
	BX LR 	
	ENDP
		

delay_motor	PROC
	; Delay for software debouncing
	LDR	r2, =0x9AAA				;tune this for speeds maybe too slow
delayloop_motor
	SUBS	r2, #1
	BNE	delayloop_motor
	BX LR
	
	ENDP

seven_seg_A PROC

	LDR r0, =GPIOA_BASE ; Loading base register
	LDR r1, [r0, #GPIO_ODR]
	BIC r1, r1, #0xF00;		clear pins 11 10 9 8
	ORR r1, r1, #0xA00;
	STR r1, [r0, #GPIO_ODR] ; Offsetting the base register to access the ODR
	BX LR
	ENDP
	
seven_seg_B PROC

	LDR r0, =GPIOA_BASE ; Loading base register
	LDR r1, [r0, #GPIO_ODR]
	BIC r1, r1, #0xF00;		clear pins 11 10 9 8
	ORR r1, r1, #0xB00;
	STR r1, [r0, #GPIO_ODR] ; Offsetting the base register to access the ODR
	BX LR
	ENDP
	
seven_seg_C PROC

	LDR r0, =GPIOA_BASE ; Loading base register
	LDR r1, [r0, #GPIO_ODR]
	BIC r1, r1, #0xF00;		clear pins 11 10 9 8
	ORR r1, r1, #0xC00;
	STR r1, [r0, #GPIO_ODR] ; Offsetting the base register to access the ODR
	BX LR
	ENDP



; Keypad functions and subfunctions

; Returns button 0-9 (* = 10 AND # = 11) - only returns once a button has been pressed, it remains in the main loop otherwise
identifyButton	PROC
	PUSH{LR, r5, r6, r8, r9, r10, r11} ; Push all of the registers that are utilized here

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
	MOVEQ r2, #3; RESULT
	BEQ displaykey
	CMP R5, #0x4
	MOVEQ R5, #50; '2'
	MOVEQ r2, #2 ; RESULT
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #49; '1'
	MOVEQ r2, #1 ; RESULT
	BEQ displaykey
		
row1
	CMP R5, #0x8
	MOVEQ R5, #54; '6'
	MOVEQ r2, #6 ; RESULT
	BEQ displaykey
	CMP R5, #0X4
	MOVEQ R5, #53; '5'
	MOVEQ r2, #5 ; RESULT
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #52; '4'
	MOVEQ r2, #4 ; RESULT
	BEQ displaykey

row2
	CMP R5, #0x8
	MOVEQ R5, #57; '9'
	MOVEQ r2, #9 ; RESULT
	BEQ displaykey
	CMP R5, #0x4
	MOVEQ R5, #56; '8'
	MOVEQ r2, #8 ; RESULT
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #55; '7'
	MOVEQ r2, #7 ; RESULT
	BEQ displaykey

row3
	CMP R5, #0x8
	MOVEQ R5, #35; '#'
	MOVEQ r2, #11; RESULT
	BEQ displaykey
	CMP R5, #0X4
	MOVEQ R5, #48; '0'
	MOVEQ r2, #0; RESULT
	BEQ displaykey
	CMP R5, #0x2
	MOVEQ R5, #42; '*'
	MOVEQ r2, #10; RESULT
	BEQ displaykey
	
displaykey
	PUSH{r2} ; Save the original value for return
	LDR	r0, =char1
	STR	r5, [r0]
	MOV r1, #1    ; Second argument
	BL USART2_Write
	POP{r2}
	POP{LR, r5, r6, r8, r9, r10, r11}
	MOV r0, r2 ; Moving the result from r0 to r2
	BX LR		; after displaying a key returns to start
	ENDP		

; END OF IDENTIFY BUTTON PROCESS -------------------------------------------------------------------------------------------
	

delay	PROC
	PUSH{LR}
	; Delay for software debouncing
	LDR	r2, =0x9999
delayloop
	SUBS	r2, #1
	BNE	delayloop
	POP{LR}
	BX LR
	
	ENDP



; RETURNS Pin 1-3 as HIGH depending on voltage
checkCols PROC
	PUSH{LR}
	; Checking columns of the keypad
	LDR r1, =GPIOB_BASE
	LDR r2, [r1, #GPIO_IDR]
	AND r2, r2, #0xE ; Mask everything but bits 1-3
	MOV r0, r2
	POP{LR}
	BX LR 
	
	ENDP


; RETURNS 1 if the row test is positive and 0 if it is negative
checkRow PROC
	PUSH{LR}
	; ROW 0 SET
	LDR r1, =GPIOC_BASE
	LDR r2, [r1, #GPIO_ODR] 
	AND r2, r2, #0xFFFFFFF0 ; Clearing the last 4 bits of the register
	EOR r0, r0, #0xF ; This puts r0 with proper calling convention and toggles pins i.e. 0111
	ORR r2, r2, r0 ; This copies the last 4 bits of r0 into r2
	STR r2, [r1, #GPIO_ODR] ; Assuming non-inverted - this is finished
	
	; DELAY 1
	BL delay
	
	
	; TEST COL AGAIN
	BL checkCols
	MOV r3, r0	;value of test row is in r3 now
	CMP r3, #0xE ; Check if all cols are high with the new input
	MOVEQ r0, #0 ; Return 0 if no button is pressed
	MOVNE r0, #1 ; Return 1 for a button is being pressed 
	
	POP{LR}
	BX LR
	ENDP
					
	ALIGN			

	AREA myData, DATA, READWRITE
	ALIGN
char1	DCD	43
testByte DCD 0 ; THIS IS PURELY A TEST BYTE TO ENSURE THAT TERATERM IS WORKING PROPERLY
	END