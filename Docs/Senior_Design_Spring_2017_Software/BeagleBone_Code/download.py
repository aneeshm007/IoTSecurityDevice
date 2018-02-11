from subprocess import call

keys_file = '/root/Dropbox-Uploader/dropbox_uploader.sh download "senior_design Team Folder/IMAGES/keys.txt" /var/lib/cloud9/VIP/KEYS/keys.txt '
user_file = '/root/Dropbox-Uploader/dropbox_uploader.sh download "senior_design Team Folder/IMAGES/user.txt" /var/lib/cloud9/VIP/USER/user.txt '
#delete_keys_file = '/root/Dropbox-Uploader/dropbox_uploader.sh delete "senior_design Team Folder/IMAGES/keys.txt" '


call ([keys_file], shell=True)
call([user_file], shell = True)
#call ([delete_keys_file], shell=True)

