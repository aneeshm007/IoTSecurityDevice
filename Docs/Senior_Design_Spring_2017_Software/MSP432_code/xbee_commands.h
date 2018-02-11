#ifndef XBEE_COMMANDS_H_
#define XBEE_COMMANDS_H_

#include "xbee_driver.h"

char OK_RESPONSE[3] = "OK\n";

// "CMD_STR" --- CMD LENGTH --- PARAMETER (0 - no, 1 - optional, 2 - necessary) --- PARAM LENGTH
const XBEE_CMD AT_CMD = {"AT", 2, 0, 0};
const XBEE_CMD WR_CMD = {"ATWR", 4, 0, 0};
const XBEE_CMD RE_CMD = {"ATRE", 4, 0, 0};
const XBEE_CMD AC_CMD = {"ATAC", 4, 0, 0};
const XBEE_CMD BD_CMD = {"ATBD", 4, 1, 1};
const XBEE_CMD SB_CMD = {"ATSB", 4, 2, 1};
const XBEE_CMD RO_CMD = {"ATRO", 4, 0, 0};
const XBEE_CMD EE_CMD = {"ATEE", 4, 2, 1};
const XBEE_CMD DH_CMD = {"ATDH", 4, 1, 8};
const XBEE_CMD DL_CMD = {"ATDL", 4, 1, 8};
const XBEE_CMD KY_CMD = {"ATKY", 4, 2, 32};
const XBEE_CMD CN_CMD = {"ATCN", 4, 0, 0};
const XBEE_CMD CT_CMD = {"ATCT", 4, 1, 2};
const XBEE_CMD ID_CMD = {"ATID", 4, 1, 4};
const XBEE_CMD OI_CMD = {"ATOI", 4, 0, 4};
const XBEE_CMD SH_CMD = {"ATSH", 4, 0, 6};
const XBEE_CMD SL_CMD = {"ATSL", 4, 0, 8};


#endif /* XBEE_COMMANDS_H_ */
