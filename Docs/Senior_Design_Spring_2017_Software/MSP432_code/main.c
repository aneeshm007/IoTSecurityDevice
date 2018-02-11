#include <string.h>
#include "driverlib.h"
#include "ov2640_driver.h"
#include "spi_driver.h"
#include "xbee_driver.h"
#include "motion_sensor.h"

// Array where image is stored
extern uint8_t image_buffer[];

// XBee UART buffer
extern uint8_t RXBuffer[];

// Capture_req flag, set by PIR motion sensor ISR
unsigned char capture_req = 0;

/* Function that changes SMCLK to 12MHz for use with XBee UART
 * ---- 12MHz not necessary, however was used during our development
 * ---- if changing from 12MHz need to recalculate UART baud rate register
 * http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSP430BaudRateConverter/index.html
 */
void init_SMCLK() {
	/* Setting SMCLK to 12MHz to use for UART with XBEE */
	MAP_CS_initClockSignal(CS_SMCLK, CS_MODOSC_SELECT, CS_CLOCK_DIVIDER_2);
}

int main(void) {
	int size = 0;

    /* Stop WDT  */
    MAP_WDT_A_holdTimer();

    init_SMCLK();	// initialize/start the clock signal to be provided to the OV2640

    init_ov2640();	// initialize OV2640 CMOS sensor -- JPEG output, 640x480

    spi_init();		// initialize SPI for communication with the FPGA and FIFO of the Arducam

	init_XBEE();	// setup UART and wait for XBee module to join the network

    motion_sensor_init();	// initial motion sensor on P3.0 -- interrupt on

    MAP_Interrupt_enableMaster();	// enable global interrupts

	new_read();		// call function to set RXBuffer index = 0

	// While loop that waits for XBee command via UART
	while (1) {
		//MAP_PCM_gotoLPM4();	-- need to add LPM3.5, wake-up via RTC every 30 seconds
		if(RXBuffer[0] != 0x00) {	// check if the RXBuffer has new data (via UART from XBee)
			if(RXBuffer[0] == '2') {	// session key request
				motion_sensor_disable();	// disable motion sensor interrupts
				set_session_key();
				motion_sensor_enable();		// re-enable motion sensor interrupts
			}
			if(RXBuffer[0] == '5') {	// capture image request
				motion_sensor_disable();	// disable motion sensor interrupts
				size = capture_image();		// call capture image function, which returns the image size and fill image_buffer
				image_buffer[0] = 0x10;		// set the first byte = 0x10 to indicate to ZigBee coord. image is being transmitted
				transmit_image(image_buffer, size+1);	// transmit image of size given by capture_image
				motion_sensor_enable();		// re-enable motion sensor interrupts
			}
			new_read();		// reset RXBuffer values and index
		}
		else if(capture_req == 1) {		// check if the PIR interrupts
			motion_sensor_disable();	// disable motion sensor interrupts, while capturing and transmitting
			size = capture_image();		// capture image
			image_buffer[0] = 0x10;		// set the first byte of the image = 0x10, so the coordinator knows end dev. is sending an image
			transmit_image(image_buffer, size+1);	// transmit the image
			capture_req = 0;	// reset capture request flag
			motion_sensor_enable();		// re-enable PIR interrupts after image has finished sending
		}
	}

}

/* GPIO ISR for PIR motion sensor interrupts */
void PORT3_IRQHandler(void)
{
    uint32_t status;

    status = MAP_GPIO_getEnabledInterruptStatus(GPIO_PORT_P3);
    MAP_GPIO_clearInterruptFlag(GPIO_PORT_P3, status);

    if(status & GPIO_PIN0) {
    	capture_req = 1;	// if motion sensor interrupt, set capture_req flag
    }
}

