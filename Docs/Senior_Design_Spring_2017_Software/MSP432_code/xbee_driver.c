/* DriverLib Includes */
#include "driverlib.h"

/* Standard Includes */
#include <stdint.h>
#include <string.h>
#include "xbee_driver.h"
#include "xbee_commands.h"

/* XBee defines */
#define GOT_OK 1
#define GOT_ERROR 0
#define TIMEOUT 0
#define TIMEOUT_PERIOD 3000000

/* DMA Control Table */
#ifdef ewarm
#pragma data_alignment=1024
#else
#pragma DATA_ALIGN(controlTable, 1024)
#endif
uint8_t controlTable[1024];

/* XBee UART Receive Buffer */
#define RXBuffer_size 200
uint8_t RXBuffer[RXBuffer_size];

extern uint8_t Data[];

// UART Settings Calculator :
// http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSP430BaudRateConverter/index.html

/* Below are two UART configurations for different XBee modes of operation
 * These could be reduced to one, however we were not able to use SMCLK
 * for image transfer without substantial packet loss
 */

/* UART configuration for using XBee command mode */
const eUSCI_UART_Config uartConfig = {
        EUSCI_A_UART_CLOCKSOURCE_SMCLK,          // SMCLK Clock Source
        81,                                     // BRDIV = 78
        6,                                     // UCxBRF = 2
        2,                                    // UCxBRS = 0
		EUSCI_A_UART_NO_PARITY,                  // No Parity
        EUSCI_A_UART_LSB_FIRST,                  // LSB First
        EUSCI_A_UART_ONE_STOP_BIT,               // One stop bit
		EUSCI_A_UART_MODE,                       // UART mode
		EUSCI_A_UART_OVERSAMPLING_BAUDRATE_GENERATION  // Oversampling
};

/* UART configuration for sending an image via the XBee module */
const eUSCI_UART_Config uartConfig_image =
{
        EUSCI_A_UART_CLOCKSOURCE_ACLK,          // ACLK Clock Source
        03,                                     // BRDIV = 3
        0x0,                                     // UCxBRF = 0
        0x53,                                    // UCxBRS = 0x53
		EUSCI_A_UART_NO_PARITY,                  // No Parity
        EUSCI_A_UART_LSB_FIRST,                  // LSB First
        EUSCI_A_UART_ONE_STOP_BIT,               // One stop bit
        EUSCI_A_UART_MODE,                       // UART mode
		EUSCI_A_UART_LOW_FREQUENCY_BAUDRATE_GENERATION  // No iversampling
};

/* DMA used to fill the RXBuffer when receiving data via UART */
void init_DMA() {
	memset(RXBuffer, 0x00, 100);	// reset RXBuffer, so that new data can be read in

    /* Configuring DMA module */
    MAP_DMA_enableModule();
    MAP_DMA_setControlBase(controlTable);

    /* Assigning Channel 5 to DMA_CH5_EUSCIA2RX */
    MAP_DMA_assignChannel(DMA_CH5_EUSCIA2RX);

    /* Setting Control Indexes */
    MAP_DMA_setChannelControl(UDMA_PRI_SELECT | DMA_CH5_EUSCIA2RX,
            UDMA_SIZE_8 | UDMA_SRC_INC_NONE | UDMA_DST_INC_8 | UDMA_ARB_1);
    MAP_DMA_setChannelTransfer(UDMA_PRI_SELECT | DMA_CH5_EUSCIA2RX,
            UDMA_MODE_BASIC, (void*)MAP_UART_getReceiveBufferAddressForDMA(EUSCI_A2_BASE), RXBuffer, 100);

    /* Now that the DMA is primed and setup, enabling the channels. The EUSCI
     * hardware should take over and transfer/receive all bytes */
    MAP_DMA_enableChannel(5);
}

/* Function that initializes UART operation, initialize DMA, resets the XBee module,
 * waits for XBee module to join a network, then sends the XBee devices address to the
 * coordinator.
 */
void init_XBEE() {
	char OI_response[4], SH_response[6], SL_response[8];
	const char OI_no_connect[4] = "FFFF";

    /* Selecting P3.2(RX) and P3.3(TX) in UART mode */
    MAP_GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P3,
            GPIO_PIN2 | GPIO_PIN3, GPIO_PRIMARY_MODULE_FUNCTION);

    /* Setting DCO to 12MHz */
    CS_setDCOCenteredFrequency(CS_DCO_FREQUENCY_24);

    /* Configuring UART Module */
    MAP_UART_initModule(EUSCI_A2_BASE, &uartConfig);

    /* Enable UART module */
    MAP_UART_enableModule(EUSCI_A2_BASE);

    /* Using DMA to put incoming UART in to RXBuffer */
    init_DMA();

    // commands to initialize the XBee module
    // need to eliminate the 1 second delay between each XBee command by writing a function that takes an array of XBee commands
    xbee_CMD(RE_CMD, "0", WRITE_CMD | APPLY_CHANGE | WRITE_NO_PARAM, "0");
    _delay_cycles(30000000);
    xbee_CMD(ID_CMD, "2F0A", WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");	// set pan id to random value
    _delay_cycles(30000000);
    xbee_CMD(ID_CMD, "0000", WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");	// set pan id to zero to join network
    _delay_cycles(30000000);

    xbee_CMD(OI_CMD, "0", READ, OI_response);	// set pan id to zero, so that the XBee module joins a network
    _delay_cycles(30000000);

    // wait for the node to join the network
    while(!strncmp(OI_response, OI_no_connect, 4)) {
    	xbee_CMD(OI_CMD, "0", READ, OI_response);	// check if the operating pan id has changed (node has joined a network)
        _delay_cycles(30000000);
    }

	xbee_CMD(SH_CMD, "0", READ, SH_response);	// get the serial high addr to send to coordinator
    _delay_cycles(30000000);
	xbee_CMD(SL_CMD, "0", READ, SL_response);	// get the serial low addr to send to coordinator
    _delay_cycles(30000000);

    // transmit the address of the node to the coordinator for verification
    transmit_array(SH_response, SH_CMD.cmd_param_len);
    transmit_array(SL_response, SL_CMD.cmd_param_len);
}

// Function that resets DMA destination address for a new read
void new_read() {
	memset(RXBuffer, 0x00, 100);	// reset RXBuffer, so that new data can be read in
    MAP_DMA_setChannelTransfer(UDMA_PRI_SELECT | DMA_CH5_EUSCIA2RX,
            UDMA_MODE_BASIC, (void*)MAP_UART_getReceiveBufferAddressForDMA(EUSCI_A2_BASE), RXBuffer, 100);
    MAP_DMA_enableChannel(5);
}

// Function that sets/resets DMA for an instruction from the XBee module
void reset_dma() {
	memset(RXBuffer, 0x00, 1);	// reset RXBuffer, so that new data can be read in
    MAP_DMA_setChannelTransfer(UDMA_PRI_SELECT | DMA_CH5_EUSCIA2RX,
            UDMA_MODE_BASIC, (void*)MAP_UART_getReceiveBufferAddressForDMA(EUSCI_A2_BASE), RXBuffer, 100);
    MAP_DMA_enableChannel(5);
    MAP_Interrupt_enableInterrupt(INT_DMA_INT1);
    MAP_Interrupt_disableSleepOnIsrExit();
}

void transmit_image(unsigned char array[], int length) {
    /* Disable UART module to reconfigure settings */
    MAP_UART_disableModule(EUSCI_A2_BASE);

    /* Reconfiguring UART Module for image transmission */
    MAP_UART_initModule(EUSCI_A2_BASE, &uartConfig_image);

    /* Re-enable UART module */
    MAP_UART_enableModule(EUSCI_A2_BASE);

	int i = 0;
	uint_fast8_t byte_to_transmit = 0;

	for(i = 0; i < length; i++) {
		byte_to_transmit = array[i];
		while (!(UCA2IFG&UCTXIFG));
		MAP_UART_transmitData(EUSCI_A2_BASE, byte_to_transmit);
		MAP_UART_clearInterruptFlag(EUSCI_A2_BASE, EUSCI_A_UART_TRANSMIT_INTERRUPT_FLAG );
	}

    /* Disable UART module to reconfigure settings */
    MAP_UART_disableModule(EUSCI_A2_BASE);

    /* Reconfiguring UART Module for normal operation */
    MAP_UART_initModule(EUSCI_A2_BASE, &uartConfig);

    /* Re-enable UART module */
    MAP_UART_enableModule(EUSCI_A2_BASE);
}

/* Function that transmits char array to XBee module via UART */
void transmit_array(char array[], int length) {
	int i = 0;
	uint_fast8_t byte_to_transmit = 0;

	for(i = 0; i < length; i++) {
		byte_to_transmit = array[i];
		while (!(UCA2IFG&UCTXIFG));
		MAP_UART_transmitData(EUSCI_A2_BASE, byte_to_transmit);
		MAP_UART_clearInterruptFlag(EUSCI_A2_BASE, EUSCI_A_UART_TRANSMIT_INTERRUPT_FLAG );
	}
}

// function that searches RXBuffer for response --- should be near beginning of the buffer
uint8_t wait_OK() {
	int i = 0;

	// NEED TO FIX TIMEOUT
    MAP_SysTick_enableModule();
    MAP_SysTick_setPeriod(TIMEOUT_PERIOD);	// 1 sec timeout

    while(MAP_SysTick_getValue() != TIMEOUT_PERIOD-1) {
		for(i = 2; i < RXBuffer_size; i++) {
			if(RXBuffer[i - 2] == 'O' && RXBuffer[i - 1] == 'K' && RXBuffer[i] == 0x0D)
				return GOT_OK;
			else if(RXBuffer[i - 2] == 'E' && RXBuffer[i - 1] == 'R' && RXBuffer[i] == 'R')
				return GOT_ERROR;
		}
	}

	MAP_SysTick_disableModule();

    return 0;
}

// function that searches RXBuffer for carriage return (end of response)
uint8_t wait_CR() {
	int i = 0;

	// NEED TO FIX TIMEOUT
    MAP_SysTick_enableModule();
    MAP_SysTick_setPeriod(TIMEOUT_PERIOD);	// 1 sec timeout

	while(MAP_SysTick_getValue() != TIMEOUT_PERIOD-1) {
		for(i = 0; i < RXBuffer_size; i++) {
			if(RXBuffer[i] == 0x0D)
				return GOT_OK;
		}
	}

	MAP_SysTick_disableModule();

	return 0;
}

/* Function that sends command to XBEE module
 * XBEE_CMD cmd --- is the structure for the specific command
 * unsigned char param[] --- is the optional parameter of the command to be sent
 * unsigned char option --- determines different aspects of command (write to non-volatile XBEE mem, apply changes imm., etc.)
 */
uint8_t xbee_CMD(XBEE_CMD cmd, char param[], unsigned char option, char *read_value) {

	new_read(); // restart DMA to get new responses
	transmit_array(XBEE_CMD_START, 3);	// enter command mode
	if(!wait_OK()) // wait for OK, ERROR or TIMEOUT
		return 0;	// return 0, if failed

	_delay_cycles(1000);

	new_read(); // restart DMA to get new response
	transmit_array(cmd.cmd_name, cmd.cmd_length);	// send command
	if(cmd.cmd_param == 2) // if parameter required --- transmit to XBEE module
		transmit_array(param, cmd.cmd_param_len);
	else if(cmd.cmd_param == 1 && (option & 0x08) == 0x08) // parameter optional, but caller of functions is using (option == 0x08)
		transmit_array(param, cmd.cmd_param_len);
	transmit_array(XBEE_CR, 1); // transmit carriage return
	if((option & READ) != READ) {	// reading --- dont need to check for 'OK'
		if(!wait_OK()) // wait for OK, ERROR or TIMEOUT
			return 0;	// return 0, if failed
	}
	else {
		if(!wait_CR())	// wait for end of response from XBee module
			return 0;
		memcpy(read_value, RXBuffer, cmd.cmd_param_len);
	}

	if((option & 0x01) == 0x01) {	// want to write the changes to the non-volatile memory on the XBEE module
		new_read(); // restart DMA to get new response
		transmit_array(XBEE_WR, 5);	// send command to write to XBEE non-volatile memory
		if(!wait_OK()) // wait for OK, ERROR or TIMEOUT
			return 0;	// return 0, if failed
	}
	if((option & 0x02) == 0x02) {	// want to apply the changes immediately
		new_read(); // restart DMA to get new response
		transmit_array(XBEE_AC, 5);	// send command to apply changes to XBEE module
		if(!wait_OK()) // wait for OK, ERROR or TIMEOUT
			return 0;	// return 0, if failed
	}

	new_read(); // restart DMA to get new response
	transmit_array(XBEE_CMD_EXIT, 5);	// send command to exit command mode
	if(!wait_OK()) // wait for OK, ERROR or TIMEOUT
		return 0;	// return 0, if failed

	return 1;
}

int read_coordinates() {
	int i = 0;

	if(!wait_CR())	// wait for end of response from XBee module
		return 0;

	for(i = 0; i < COORD_LENGTH; i++) {
		x_coord[i] = RXBuffer[i+1];
	}

	for(i = 0; i < COORD_LENGTH; i++) {
		y_coord[i] = RXBuffer[i+1+COORD_LENGTH];
	}

	return 1;
}

// function takes in hex value and converts to ascii hex value
void hex_to_char(unsigned char *format_str, unsigned char hex_value) {
	unsigned char upper = (0xF0 & hex_value) >> 4, lower = 0x0F & hex_value;	// mask upper and lower bytes

	// convert hex values to ascii
	if(upper >= 10)
		upper += 55;
	else
		upper += 48;
	if(lower >= 10)
		lower += 55;
	else
		lower += 48;

	format_str[0] = upper;
	format_str[1] = lower;
}

// convert array of hex values to equivalent ascii value array
void hex_array_to_ascii(unsigned char *format_str, unsigned char hex_value[], int length) {
	int i = 0;

	for(i = 0; i < length; i++) {
		hex_to_char(&format_str[i*2], hex_value[i]);
	}
}

// function that sets the address of the XBee coordinator
void setup_node() {
	int i = 0;
	//unsigned char addr_high_str[ADDR_HIGH_LEN * 2], addr_low_str[ADDR_HIGH_LEN * 2];

	// get PAN ID from the RX buffer
	for(i = 0; i < PAN_ID_LEN; i++)
		pan_id[i] = RXBuffer[i + 1];
	for(i = 0; i < SESSION_KEY_LEN; i++)
		session_key[i] = RXBuffer[i + 1 + PAN_ID_LEN];

//	hex_array_to_ascii(addr_high_str, addr_high, ADDR_HIGH_LEN);
//	hex_array_to_ascii(addr_low_str, addr_low, ADDR_LOW_LEN);

    xbee_CMD(ID_CMD, pan_id, WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");
    _delay_cycles(30000000);
	xbee_CMD(EE_CMD, "1", WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");
	//xbee_CMD(KY_CMD, session_key_str, WRITE_CMD | APPLY_CHANGE | PARAMETER);
	_delay_cycles(30000000);
	xbee_CMD(KY_CMD, session_key, WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");
	_delay_cycles(30000000);

}

// function that sets the session key
int set_session_key() {
	int i = 0;
	//unsigned char session_key_str[ADDR_HIGH_LEN * 2];

	if(!wait_CR())	// wait for end of response from XBee module
		return 0;

	// get addresses from the RX buffer !!!! NEED TO CHANGE WHEN GETTING FROM FPGA
	for(i = 0; i < SESSION_KEY_LEN; i++)
		session_key[i] = RXBuffer[i + 1];

	//hex_array_to_ascii(session_key_str, session_key, SESSION_KEY_LEN * 2);

	xbee_CMD(EE_CMD, "1", WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");
	//xbee_CMD(KY_CMD, session_key_str, WRITE_CMD | APPLY_CHANGE | PARAMETER);
	_delay_cycles(30000000);
	xbee_CMD(KY_CMD, session_key, WRITE_CMD | APPLY_CHANGE | PARAMETER, "0");
	_delay_cycles(30000000);

	new_read(); // restart DMA to get new response

	if(!wait_OK()) // wait for OK, ERROR or TIMEOUT
		return 0;	// return 0, if failed

	// Send two 'OK's to the ZigBee coordinator
    transmit_array(OK_RESPONSE, 2);
	_delay_cycles(30000000);
    transmit_array(OK_RESPONSE, 2);
	_delay_cycles(30000000);
    transmit_array(OK_RESPONSE, 2);

	return 1;
}

/* EUSCI A2 UART ISR */
void EUSCIA2_IRQHandler(void)
{
    uint32_t status = MAP_UART_getEnabledInterruptStatus(EUSCI_A2_BASE);

    MAP_UART_clearInterruptFlag(EUSCI_A2_BASE, status);

    if(status & EUSCI_A_UART_RECEIVE_INTERRUPT_FLAG)
    {
        MAP_UART_transmitData(EUSCI_A2_BASE, MAP_UART_receiveData(EUSCI_A2_BASE));
        _delay_cycles(10);
    }
}
