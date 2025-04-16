# Pinout Assignments for Project

## GPIOA - INPUT
Keypad input: 3, 2, 1 \
LED: 5

## GPIOB - OUTPUT
Keypad output: 7, 6, 3, 2 \
LCD output: 15, 14, 11, 10

## GPIOC - OUTPUT
Motor doors: 7, 6, 5, 4
Motor train wheels: 3, 2, 1, 0
Interrupt Button (Onboard Blue Button): 13


## Brian Notes
TERM PROJECT LIST

-is the project in C only,,, only one main.s or can import C code into Main.s

REUSE:



PIN OUT:
key pad -, 1 2 3 , * stop , # - ret A (rot mot 9)
key pad - PC321 -> PA321



NEW (BONUS):
3 motors
PWM



project desc:
MIN
A->B->C

- 3 rot per transitionA
- every 3 rot [A,B,C]; ascii
- A->C  skip [B]
- a wait period, delay using RTC clk?
- doors

equiment :
2 motor
1 keypad
-1 user button PA13>?


stepper masks M1 and M2;

RIGHT CW:
1001  0101 0110 1010
  1		2	3	 4

motor 1,2


