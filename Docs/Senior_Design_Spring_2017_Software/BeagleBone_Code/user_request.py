from twilio.rest import TwilioRestClient
import pyinotify
from subprocess import call
import functools
import sys

import Adafruit_BBIO.UART as UART
import binascii
import serial
import datetime
import time
import os

 
#ser = serial.Serial(port = "/dev/ttyO1", baudrate=9600)
 
ser = serial.Serial(port = "/dev/ttyO1", baudrate=9600)
ser.close()
ser.open()
if ser.isOpen():
	print "Serial is open!"

delete_user = '/root/Dropbox-Uploader/dropbox_uploader.sh delete "senior_design Team Folder/IMAGES/user.txt" '

wm = pyinotify.WatchManager()  # Watch Manager

mask = pyinotify.IN_DELETE | pyinotify.IN_CLOSE_WRITE  | pyinotify.IN_MOVED_TO | pyinotify.IN_CREATE # watched events

print("hello")


#function to  read the value passed into textfile from app
#which represents what action to take place
#depending on content execute desired functions

def user_request():
    request= open('USER/user.txt', 'r')
    command = request.readline()
    

    path1 = "USER/user.txt"
    path2 = "VIP/KEYS/keys.txt"

    
    
    if(command.startswith('5')):
        print("user request for image")
        ser.write("5");
        
        #remove the file after executiion
        os.remove('USER/user.txt')
            
      
    elif (command.startswith('6')):  
        print("key change request")
        

       
    

class EventHandler(pyinotify.ProcessEvent):

        
    def process_IN_CLOSE_WRITE(self, event):
        print "Creating keys.txt in folder USER:", event.pathname
        user_request()
        call([delete_user], shell = True)

    

    def process_IN_DELETE(self, event):
        print "Removing in folder USER: ", event.pathname

    def process_IN_MOVED_TO(self, event):
        print "moving to Folder USER: ", event.pathname

handler = EventHandler()
notifier = pyinotify.Notifier(wm, handler)
wdd = wm.add_watch('/var/lib/cloud9/VIP/USER', mask, rec=True)
notifier.loop()
