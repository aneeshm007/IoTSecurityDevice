/* DriverLib Includes */
#include "spi_driver.h"
#include "driverlib.h"

#define ASSERT_CS()          (P4OUT &= ~BIT6)
#define DEASSERT_CS()        (P4OUT |= BIT6)

/* SPI Master Configuration Parameter */
volatile eUSCI_SPI_MasterConfig spiConfig =
{
        EUSCI_B_SPI_CLOCKSOURCE_SMCLK,      	       // SMCLK Clock Source
		0,                                   		// SMCLK 24Mhz
        1000000,                                    // SPICLK = 1Mhz
        EUSCI_B_SPI_MSB_FIRST,                     // MSB First
		EUSCI_B_SPI_PHASE_DATA_CAPTURED_ONFIRST_CHANGED_ON_NEXT,    // Phase
        EUSCI_B_SPI_CLOCKPOLARITY_INACTIVITY_LOW, // High polarity
        EUSCI_B_SPI_3PIN                           // 3Wire SPI Mode
};

void spi_init(void)
{
	/* I2C Clock Soruce Speed */
	spiConfig.clockSourceFrequency = MAP_CS_getSMCLK();

    /* Selecting P1.5(SCK) P1.6(MOSI) and P1.7(MISO) in SPI mode */
	GPIO_setAsPeripheralModuleFunctionInputPin(GPIO_PORT_P1,
			GPIO_PIN5 | GPIO_PIN6 | GPIO_PIN7, GPIO_PRIMARY_MODULE_FUNCTION);

	/* CS setup. */
    GPIO_setOutputLowOnPin(GPIO_PORT_P4, GPIO_PIN6);
    GPIO_setAsOutputPin(GPIO_PORT_P4, GPIO_PIN6);

    /* Configuring SPI in 3wire master mode */
	SPI_initMaster(EUSCI_B0_BASE, (const eUSCI_SPI_MasterConfig *)&spiConfig);

	/* Enable SPI module */
	SPI_enableModule(EUSCI_B0_BASE);
}

void spi_Write(unsigned char addr, unsigned char value)
{
    ASSERT_CS();

    while (!(UCB0IFG&UCTXIFG));		// wait for TX flag
	UCB0TXBUF = addr;				// send register address
	while (!(UCB0IFG&UCRXIFG));
	UCB0RXBUF;

	while (!(UCB0IFG&UCTXIFG));		// wait for TX flag
	UCB0TXBUF = value;				// send register value to write
	while (!(UCB0IFG&UCRXIFG));
	UCB0RXBUF;

    DEASSERT_CS();
}

int spi_Read(unsigned char addr, unsigned char *data, int len)
{
    int i = 0;

    ASSERT_CS();

    for (i = 0; i < len; i ++)
    {
        while (!(UCB0IFG&UCTXIFG));		// wait for TX flag
        if(i >= 1) UCB0TXBUF = 0x00;	// send dummy byte if greater than 1
        else UCB0TXBUF = addr;	// send address if this is the first send
        while (!(UCB0IFG&UCRXIFG));		// wait for RX flag
        if(i >= 1) data[i - 1] = UCB0RXBUF;	// store data if the address has already been sent
        else UCB0RXBUF;	// don't care about first byte sent from Arducam
    }

    DEASSERT_CS();

    return len;
}


