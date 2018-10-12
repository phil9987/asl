start /B /wait "" "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "ASL Ubuntu Server" --type headless
start /B /wait ssh -p 2222 osboxes@localhost -t "cd asl ; git pull ; ant jar"
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11212 -vv ; /bin/bash"
TIMEOUT 5
start cmd /k ssh -p 2222 osboxes@localhost -t "cd asl ; java -jar dist/middleware-junkerp.jar  -l localhost -p 1234 -t 1 -s false -m localhost:11212 ; /bin/bash"
TIMEOUT 5
start cmd /k ssh -p 2222 osboxes@localhost -t "cd memtier_benchmark ; ./memtier_benchmark -p 1234 -n 500 --protocol=memcache_text -c 1 -x 1 -t 1 -D --ratio=1:1 ; /bin/bash"
