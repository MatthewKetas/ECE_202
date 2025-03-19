#include "stm32l476xx.h"
#include "SysClock.h"
#include "UART.h"

#include <string.h>
#include <stdio.h>

// PA.5  <--> Green LED
// PC.13 <--> Blue user button
#define LED_PIN    5
#define BUTTON_PIN 13



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

	
int main(void){

	System_Clock_Init(); // Switch System Clock = 80 MHz
	UART2_Init(); // Communicate with Tera Term
	
	//demo_of_printf_scanf();

	// ****************************//
	// USER CODE GOES HERE
	// ****************************//
	
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

	
	// Configure PC13
	// Setting the mode of GPIOC to input
	GPIOC->MODER &= ~(0x0C000000); // Clear the mode of pin C13
	GPIOC->MODER |= 0x00000000; // Set the mode of pin C13 to input
	
	//Setting the mode of GPIOC PC13 to no pull up / pull down
	GPIOC->PUPDR &= ~(0x0C000000); // Clear bit 26 and 27
	GPIOC->PUPDR |= 0x00000000; // Set the value of 0,0 respectively for bits 26, 27
	
	// Read from PC13 and Set LED light
	// The blue user button is pulled up externally. 
	// The GPIO input is low if the button is pressed down.
	
	
	//Read from button input and turn on LED when pressed down
	//GPIOC->IDR &= ~(0x0C000000); // Mask button initially - WRITING TO AN INPUT DOES NOTHING WE DO NOT NEED
	GPIOA->ODR &= ~(0x00000020); // Masking the LED pin A5
	while(1){
		int x = (GPIOC->IDR & 0x00002000); //Reading the input from Pin C13
		if(!x){ 
			GPIOA->ODR ^= (0x00000020); //If input button active low turn on
		}
	}
}
