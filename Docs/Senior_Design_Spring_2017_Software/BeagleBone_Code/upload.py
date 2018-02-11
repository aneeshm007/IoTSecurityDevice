from subprocess import call
import time
from twilio.rest import TwilioRestClient
import pyinotify
import functools
import sys
import json
import urllib2




def sendNotification(token, channel, message):
	data = {
		"body" : message,
		"message_type" : "text/plain"
	}

	req = urllib2.Request('http://api.pushetta.com/api/pushes/{0}/'.format(channel))
	req.add_header('Content-Type', 'application/json')
	req.add_header('Authorization', 'Token {0}'.format(token))

	response = urllib2.urlopen(req, json.dumps(data))
# Test the function:    
 

photofile = '/root/Dropbox-Uploader/dropbox_uploader.sh -s upload  /var/lib/cloud9/VIP/IMAGES/*.jpg "senior_design Team Folder/IMAGES/" '
photofile1 = '/root/Dropbox-Uploader/dropbox_uploader.sh -s upload  /var/lib/cloud9/VIP/IMAGES/*.png "senior_design Team Folder/IMAGES/" ' 
text_file = '/root/Dropbox-Uploader/dropbox_uploader.sh upload /var/lib/cloud9/VIP/IMAGES/*.txt "senior_design Team Folder/IMAGES/" '

# // account in twilio insert
twilio_account_sid = "AC97db56dbae72a0e3fd9b998032ef0955"
twilio_auth_token =  "4e39af7cf110c8124487dd4ebe369d43"
# The phone number is provied by Twilio
sTwilioNumber = "5714464495"
# The phone number of the receiver 
sSMSSender = "7035376654"

TwilioClient = TwilioRestClient(twilio_account_sid, twilio_auth_token)
n=0

# function to send text message from twilio to my number.
def SendSMS(sMsg):
  try:
    sms = TwilioClient.sms.messages.create(body="{0}".format(sMsg),to="{0}".format(sSMSSender),from_="{0}".format(sTwilioNumber)) 
  except:
    print "Error inside function SendSMS"
    pass

# only one wm to watch multiple folders.
wm = pyinotify.WatchManager()  # Watch Manager

mask = pyinotify.IN_DELETE | pyinotify.IN_CLOSE_WRITE  | pyinotify.IN_MOVED_TO # watched events
#this one watchs IMAGES folder
class EventHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, event):
        print "Creating:", event.pathname
        call ([photofile], shell=True)   
        call ([photofile1], shell=True)
        sendNotification("839477d92ca41178404f6bb77525d019328a913a", "LowPowerNodes", "NEW IMAGES: https://www.dropbox.com/sh/hl3lpn7gbssoj5i/AACswkB6uUHXIpNcTCbdyNy6a?dl=0")
        #SendSMS('NEW IMAGES: https://www.dropbox.com/sh/hl3lpn7gbssoj5i/AACswkB6uUHXIpNcTCbdyNy6a?dl=0')
        

    def process_IN_DELETE(self, event):
        print "Removing:", event.pathname
        #call ([delete_file], shell=True)
    
    def process_IN_MOVED_TO(self, event):
        print "moving", event.pathname
        call ([photofile], shell=True)   
        call ([photofile1], shell=True)
        call ([text_file], shell=True)
        sendNotification("839477d92ca41178404f6bb77525d019328a913a", "senior_design", "NEW IMAGES: https://www.dropbox.com/sh/ylku9lar7uphdrr/AADxAXdHKt7eNwK16hN9er70a?dl=0")

#
        #SendSMS('new files')
        
handler = EventHandler()

#notifier should be same to watch another folder. Only an function even watch is change(handler1) 
notifier = pyinotify.Notifier(wm, handler)

#wdd is same. only directory and mask1 change. 
wdd = wm.add_watch('/var/lib/cloud9/VIP/IMAGES', mask, rec=True)

notifier.loop()


#c_file = '/root/Dropbox-Uploader/dropbox_uploader.sh upload /var/lib/cloud9/VIP/IMAGES/*.c "senior_design Team Folder/images/" '
#py_file = '/root/Dropbox-Uploader/dropbox_uploader.sh upload /var/lib/cloud9/VIP/IMAGES/*.py "senior_design Team Folder/images/" '
#js_file = '/root/Dropbox-Uploader/dropbox_uploader.sh upload /var/lib/cloud9/VIP/IMAGES/*.js "senior_design Team Folder/images/" '

#call ([keys_file], shell=True)
#call([user_file], shell = True)


#call ([c_file], shell=True)
#call ([py_file], shell=True)
#call ([js_file], shell=True)





  

