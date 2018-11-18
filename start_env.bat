start /B /wait "" "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "ASL Ubuntu Server" --type headless
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11212 -vv ; /bin/bash"
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11213 -vv ; /bin/bash"
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11214 -vv ; /bin/bash"
#CALL deploy_new.bat
