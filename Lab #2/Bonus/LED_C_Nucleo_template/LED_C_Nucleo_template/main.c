#include "stm32l476xx.h"
#include "SysClock.h"
#include "UART.h"

#include <string.h>
#include <stdio.h>

// PA.5  <--> Green LED
// PC.13 <--> Blue user button
#define LED_PIN    5
#define BUTTON_PIN 13

const uint32_t short_delay = 400;
const uint32_t long_delay = 800;

// Delaying for miliseconds
void delay_ms(uint32_t ms){
	  volatile uint32_t iterator; // Need volatile to let compiler know variable might change at any time
    const uint32_t loop_per_ms = 8000; 
    while (ms > 0) { // Looping through desired # of miliseconds
      for (iterator = 0; iterator < loop_per_ms; iterator++){} // Must keep volatile variable in for loop
			ms--;
    }
}


void demo_of_printf_scanf(){
	char rxByte;
	printf("Are you enrolled in ECE 202 (Y or N ):\r\n");
	scanf ("%c", &rxByte);
	if (rxByte == 'N' || rxByte == 'n'){
		printf("You should not be here!!!\r\n\r\n");
	}
	else if (rxByte == 'Y' || rxByte == 'y'){
		printf("Welcome!!! \n\r\n\r\n");
	}
}

// LETTER AND MORSE CODE FUNCTIONS --------------------------------------------

void short_toggle() {
	GPIOA->ODR |= (0x00000020); // Mask LED pin
	GPIOA->ODR ^= (0x00000020); //Toggle LED pin on
	delay_ms(short_delay); // Wait
	GPIOA->ODR ^= (0x00000020); //Toggle LED pin off
	delay_ms(short_delay); // Wait
}

void long_toggle() {
	GPIOA->ODR |= (0x00000020); // Mask LED pin
	GPIOA->ODR ^= (0x00000020); //Toggle LED pin on
	delay_ms(long_delay);
	GPIOA->ODR ^= (0x00000020); //Toggle LED pin off
	delay_ms(short_delay);
}


void letter_e(){
	short_toggle();
	return;
}


void letter_c(){
	// First long
	long_toggle();
	// First Short
	short_toggle();
	// Second long
	long_toggle();
	// Second short
	short_toggle();
	return;
}


void letter_i(){
	// First short
	short_toggle();
	// Second short
	short_toggle();
	return;
}

void letter_l() {
	// First Short
	short_toggle();
	// First Long
	long_toggle();
	// Second Short
	short_toggle();
	// Third Short
	short_toggle();
	return;
}

void letter_v(){
	// First Short
	short_toggle();
	// Second Short
	short_toggle();
	// Third Short
	short_toggle();
	// First Long
	long_toggle();
}

void letter_o(){
	// First Long
	long_toggle();
	// Second Long
	long_toggle();
	// Third Long
	long_toggle();
}

void number_2() {
	// First Short
	short_toggle();
	// Second Short
	short_toggle();
	// First Long
	long_toggle();
	// Second Long
	long_toggle();
	// Third Long
	long_toggle();
}

void number_0() {
	// First Long
	long_toggle();
	// Second Long
	long_toggle();
	// Third Long
	long_toggle();
	// Fourth Long
	long_toggle();
	// Fifth Long
	long_toggle();
}

void exclamation_mark(){
	// First long
	long_toggle();
	// First short
	short_toggle();
	// Second long
	long_toggle();
	// Second short
	short_toggle();
	// Third long
	long_toggle();
	// Fourth long
	long_toggle();
}

// MAIN FUNCTION ---------------------------------------------------------------

int main(void){

	System_Clock_Init(); // Switch System Clock = 80 MHz
	UART2_Init(); // Communicate with Tera Term
	
	//Masking and setting a value to the clock
	RCC->AHB2ENR &= ~(0x00000005); // Clear all bits of interests 
	RCC->AHB2ENR |= 0x00000005;   // Set bits of interests to target value
	
	
	// Configure PA5
	// Pin initialization for GPIOA - setting mode to output
	GPIOA->MODER &= ~(0x00000C00); // Clear bit 10 and bit 11 
	GPIOA->MODER |=  0x00000400; // Set the mode to output 
	
	// Setting IO pins to push/pull 
	GPIOA->OTYPER &= ~(0x00000020); // Clearing bit 5
	GPIOA->OTYPER |= 0x00000000; // Setting the mode to push/pull
	
	// Setting GPIOA to no pull up / no pull down
	GPIOA->PUPDR &= ~(0x000000C0); // Clearing bits 10 and 11
	GPIOA->PUPDR |= 0x00000000; // Setting the mode to no pu/pd
	
	// Looping for continuous morse code message
	GPIOA->ODR &= ~(0x00000020); // Masking the LED pin A5
	while(1){
		letter_i();
		delay_ms(long_delay); // Space
		
		letter_l();
		letter_o();
		letter_v();
		letter_e(); 
		delay_ms(long_delay); // Space
		
		letter_e();
		letter_c();
		letter_e();
		exclamation_mark();
		delay_ms(long_delay); // Space
	}
}
