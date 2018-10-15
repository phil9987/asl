start /B /wait "" "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "ASL Ubuntu Server" --type headless
start /B /wait ssh -p 2222 osboxes@localhost -t "cd asl ; git pull ; ant jard"
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11212 -vv ; /bin/bash"
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11213 -vv ; /bin/bash"
start cmd /k ssh -p 2222 osboxes@localhost -t "memcached -p 11214 -vv ; /bin/bash"
TIMEOUT 5
start cmd /k ssh -p 2222 osboxes@localhost -t "cd asl ; java -jar dist/middleware-junkerp.jar  -l localhost -p 1234 -t 1 -s true -m localhost:11212 localhost:11213 localhost:11214; /bin/bash"
TIMEOUT 5
start cmd /k ssh -p 2222 osboxes@localhost -t "cd memtier_benchmark ; ./memtier_benchmark -p 1234 -n 1000 --protocol=memcache_text -c 1 -x 1 -t 1 -D --ratio=1:10 --data-size=4096 --multi-key-get=10 ; /bin/bash"
