#ifndef SL_IF_TYPE_UART
#ifndef __SPI_CC3100_H__
#define __SPI_CC3100_H__

void spi_init(void);
void spi_Write(unsigned char addr, unsigned char value);
int spi_Read(unsigned char addr, unsigned char *data, int len);

#endif
#endif /* SL_IF_TYPE_UART */
