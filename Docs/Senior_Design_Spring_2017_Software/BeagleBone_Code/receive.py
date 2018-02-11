#receive in uart from xbee

import Adafruit_BBIO.UART as UART
import binascii
import serial
import datetime
import time
 
UART.setup("UART1")

num = 1

 
ser = serial.Serial(port = "/dev/ttyO1", baudrate=9600)
ser.close()
ser.open()
if ser.isOpen():
	print "Serial is open!"
	print ("are you hereee")

finished = 0;



def read_image():
    current_byte = 0;
    last_byte = 0;
    print('Timestamp: {:%Y+-%b-%d %H:%M:%S}'.format(datetime.datetime.now()))
    get_time = ('{:%Y-%b-%d %H:%M:%S}'.format(datetime.datetime.now()))
    f = open('IMAGES/'+ get_time +  '.jpg' , 'w')
    i = 0

    while(1):
        last_byte = current_byte
        current_byte = ser.read().encode('hex')
            
        if( last_byte == "ff" and current_byte == "d9"):
            print ("Image Received")
            f.close()
            return
        
        f.write(binascii.unhexlify(current_byte))
        
        



while(1):
    

    if(ser.read().encode('hex') == "10"):
        print ("Reading Image")
        read_image()
     
        
        print ("Finished Receiving")
  
	
)