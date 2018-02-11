#ifndef XBEE_DRIVER_H_
#define XBEE_DRIVER_H_

#define XBEE_CMD_START "+++"
#define XBEE_WR "ATWR\r"
#define XBEE_AC "ATAC\r"
#define XBEE_CMD_EXIT "ATCN\r"
#define XBEE_CR "\r"

#define WRITE_CMD 0x01
#define APPLY_CHANGE 0x02
#define WRITE_NO_PARAM 0x03
#define READ 0x04
#define PARAMETER 0x08

#define COORD_LENGTH 24
char x_coord[24];
char y_coord[24];

#define PAN_ID_LEN 4
char pan_id[PAN_ID_LEN];

#define SESSION_KEY_LEN 32
char session_key[SESSION_KEY_LEN];

// XBEE command structure
// cmd_param = 0 --- no parameters allowed with command
// 			 = 1 --- parameters optional
//           = 2 --- parameters required
typedef struct _xbee_cmd {
	char *cmd_name;
	unsigned int cmd_length;
	unsigned char cmd_param;
	unsigned int cmd_param_len;
}XBEE_CMD;

void init_XBEE();
void new_read();
void reset_dma();
void transmit_image(unsigned char array[], int length);
void transmit_array(char array[], int length);
uint8_t xbee_CMD(XBEE_CMD cmd, char param[], unsigned char option, char *read_value);
void setup_node();
int set_session_key();

#endif /* XBEE_DRIVER_H_ */
