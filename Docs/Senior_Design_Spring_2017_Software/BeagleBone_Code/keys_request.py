from twilio.rest import TwilioRestClient
import pyinotify
from subprocess import call
import functools
import sys
import os
from El_gamal import *

delete_keys = '/root/Dropbox-Uploader/dropbox_uploader.sh delete "senior_design Team Folder/IMAGES/keys.txt" '

wm = pyinotify.WatchManager()  # Watch Manager

mask = pyinotify.IN_DELETE | pyinotify.IN_CLOSE_WRITE  | pyinotify.IN_MOVED_TO # watched events




def user_request2():
    print("entered function")
    path_node ="/var/lib/cloud9/VIP/KEYS/keys.txt"
    
    if (os.path.exists(path_node) and os.path.getsize(path_node) > 0) : #
        print("setup new node")
        print("Rewriting Keys")
        
        Public_key = get_public_key()
        var =setup_and_rekey(Public_key,N)
        print(var[2])

        
       

class EventHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, event):
        print "Creating keys.txt in folder KEYS:", event.pathname
        user_request2()
        call([delete_keys], shell = True)


    def process_IN_DELETE(self, event):
        print "Removing in folder KEYS: ", event.pathname

    def process_IN_MOVED_TO(self, event):
        print "moving to Folder KEYS: ", event.pathname

   
   
   


handler = EventHandler()

notifier = pyinotify.Notifier(wm, handler)

wdd = wm.add_watch('/var/lib/cloud9/VIP/KEYS', mask, rec=True)


notifier.loop()



      
