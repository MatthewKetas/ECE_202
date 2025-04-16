#include "stm32l476xx.h"
#include "I2C.h"
#include "ssd1306.h"


#include <string.h>
#include <stdio.h>

void System_Clock_Init(void);
void RTC_Clock_Init(void);
void RTC_Init(void);
void LCD_Initialization(void);
void LCD_Clear(void);
void I2C_GPIO_init(void);
void DisplayString(char* messge);
char date[] = "123456";
volatile int TimeDelay;
volatile int interupt_count = 0;


void DisplayString(char* message){

	ssd1306_Fill(White);
	ssd1306_SetCursor(2,0);
	ssd1306_WriteString(message, Font_11x18, Black);
	ssd1306_UpdateScreen();	

	
}

void SysTick_Initialize (uint32_t ticks){
	RTC->WPR |= (0xCA);
	RTC->WPR |= (0x53);
	
	SysTick->CTRL = 0;				//disables the counters to allow setup
	SysTick->LOAD = ticks -1;	// loads the reload reg to allow the 16000 clk cycle for one clk tick
	SysTick->VAL = 0;					// rsts the the counter value
	SysTick->CTRL |= (0x7);  
	//sets bits 0,1,2 to 1 to use processor clk and turn on init to enable interupts from processor clk, and to enable the counter in LOAD
	
	RTC->WPR |= (0xFF);
}



void SysTick_Handler(void){
		interupt_count++;
}
	

	

int main(void){
	
	// Enable High Speed Internal Clock (HSI = 16 MHz)
  RCC->CR |= ((uint32_t)RCC_CR_HSION);
	
  // wait until HSI is ready
  while ( (RCC->CR & (uint32_t) RCC_CR_HSIRDY) == 0 ) {;}
	
  // Select HSI as system clock source 
  RCC->CFGR &= (uint32_t)((uint32_t)~(RCC_CFGR_SW));
  RCC->CFGR |= (uint32_t)RCC_CFGR_SW_HSI;  //01: HSI16 oscillator used as system clock

  // Wait till HSI is used as system clock source 
  while ((RCC->CFGR & (uint32_t)RCC_CFGR_SWS) == 0 ) {;}

	NVIC_SetPriority(SysTick_IRQn, 1);		// Set Priority to 1
	NVIC_EnableIRQ(SysTick_IRQn);					// Enable EXTI0_1 interrupt in NVIC
  
	uint32_t cycles = 16000;	
  SysTick_Initialize(cycles);
	char msg_out[9];
	

	while(1) {
			if (interupt_count == 1000){
				interupt_count = 0;
				uint32_t hours = RTC->TR &= (0x3F0000);		//copys the hours data from the interal
				hours = hours >> 4;
				hours += 0x30;		//shifts to BCD to ASCII
				uint32_t minutes = RTC->TR &= (0x7F00);
				minutes = minutes >> 2;
				minutes += 0x30;
				uint32_t seconds = RTC->TR &= (0x7F);
				seconds += 0x30;
				char ht = hours &= (0xF0);
				char hu = hours &= (0xF);
				char mt = minutes &= (0xF0);
				char mu = minutes &= (0XF);
				char st = seconds &= (0xF0);
				char su = seconds &= (0xF);
				msg_out[0] = ht;
				msg_out[1] = hu;
				msg_out[2] = ':';
				msg_out[3] = mt;
				msg_out[4] = mu;
				msg_out[5] = ':';
				msg_out[6] = st;
				msg_out[7] = su;
				
				DisplayString(msg_out);
				
			}
		}
  // Dead loop & program hangs here
	while(1){	}
}




	
