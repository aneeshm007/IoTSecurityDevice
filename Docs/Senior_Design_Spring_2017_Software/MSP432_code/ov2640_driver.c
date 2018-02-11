/* DriverLib Includes */
#include <string.h>
#include "driverlib.h"
#include "i2c_driver.h"
#include "ov2640_regs.h"
#include "spi_driver.h"

/* Error Codes */
#define WRITE_ERROR -1
#define READ_ERROR -2
#define DEVICE_ERROR -3

/* OV2640 I2C Address */
#define OV2640_ADDRESS 0x30

/*
 * The below sccb functions utilize the i2c_driver functions from TI
 */

/* Function that reads a register of the OV2640 CMOS sensor
 * value is the read in value */
bool sccb_read_reg(uint8_t addr, uint8_t reg, uint8_t *value) {
	uint8_t val = 0x00;

	readI2C(addr, reg, &val, 1);

	*value = val;

	if(val) return true;
	else return false;
}

// wrapper function for writeI2C
bool sccb_write_reg(uint8_t addr, uint8_t reg, uint8_t value) {
	return writeI2C(addr, reg, (uint8_t *)&value, 1);
}

/* Function that writes an array of registers/value pairs to the OV2640 CMOS sensor */
bool sccb_write_reg_array(uint8_t addr, const struct sensor_reg array[]) {
	int i = 0;

	while(!(array[i].reg == 0xFF && array[i].val == 0xFF)) {
		if(!sccb_write_reg(addr, array[i].reg, array[i].val)) return false;
		i++;
	}
	return true;
}

/* Function that initialize the OV2640 registers for JPEG, 640x480 operation */
int8_t init_OV2640_regs(void) {
	uint8_t vid = 0x00, pid = 0x00;

	if(!sccb_write_reg(OV2640_ADDRESS, 0xFF, 0x01)) return WRITE_ERROR;		// return write error if the write failed (NACK received)

	if(!sccb_read_reg(OV2640_ADDRESS, 0x0a, &vid)) return READ_ERROR;	// read values of OV2640 id
	if(!sccb_read_reg(OV2640_ADDRESS, 0x0a, &pid)) return READ_ERROR;	// return read error if read failed

    if ((vid != 0x26 ) && (( pid != 0x41 ) || ( pid != 0x42 ))){
        return DEVICE_ERROR;	// check the device id against the anticipated values, return device error if wrong values
    }

    sccb_write_reg(OV2640_ADDRESS, 0x12, 0x80);		// reset the registers in the OV2640

    _delay_cycles(300000);	// delay after SW reset of OV2640

    // configure OV2640 registers for operation --- JPEG, 640x480
    sccb_write_reg_array(OV2640_ADDRESS, OV2640_JPEG_INIT);
    sccb_write_reg_array(OV2640_ADDRESS, OV2640_YUV422);
    sccb_write_reg_array(OV2640_ADDRESS, OV2640_JPEG);
    sccb_write_reg(OV2640_ADDRESS, 0xFF, 0x01);
    sccb_write_reg(OV2640_ADDRESS, 0x15, 0x00);
    sccb_write_reg_array(OV2640_ADDRESS, OV2640_640x480_JPEG);

	return 0;
}

/* Function that sets up image_buffer array, I2C for OV2640, and OV2640 registers */
void init_ov2640() {
    memset(image_buffer, 0x00, 10000);	// clear the memory allocated for the image

	initI2C();		// initialize I2C between MSP432 and OV2640

	_delay_cycles(20000);

    init_OV2640_regs();	// initialize OV2640 registers/verify OV2640 over I2C
}

/* Function that captures an image --- returns image size */
int capture_image() {
    unsigned char complete_flag = 0x00, size1 = 0x00, size2 = 0x00, size3 = 0x00;

    spi_Write(0x80, 0x27);	// write to test register

	spi_Read(0x00, &complete_flag, 2);	// read the test register just written to

	if(complete_flag != 0x27) return 0;	// if value does not equal the value written --- return 0

    spi_Write(0x84, 0x01);	// clear FIFO done flag
    spi_Write(0x84, 0x02);	// start capture
	spi_Read(0x41, &complete_flag, 2);	// read complete flag

    while((complete_flag & 0x08) != 0x08) {	// wait for the complete flag to be set
    	spi_Read(0x41, &complete_flag, 2);
    	_delay_cycles(10);
    }

    // read bytes of the image size from Arducam
    spi_Read(0x42, &size1, 2);
    spi_Read(0x43, &size2, 2);
    spi_Read(0x44, &size3, 2);

    // shift bytes into integer value of image size
    int size = ((size3 << 16) | (size2 << 8) | size1) & 0x07fffff;

    if(size >= 60000) size = 60000;		// if size bigger than allocated for an image --- set to max

    spi_Read(0x3c, image_buffer, size);	// read the image from the Arducam

    return size;
}

