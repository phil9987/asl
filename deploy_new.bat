start /B /wait ssh -p 2222 osboxes@localhost -t "cd asl ; git pull ; ant jard"
start cmd /k ssh -p 2222 osboxes@localhost -t "cd asl ; java -jar dist/middleware-junkerp.jar  -l localhost -p 1234 -t 1 -s true -m localhost:11212 localhost:11213 localhost:11214; /bin/bash"
TIMEOUT 5
start /B /wait ssh -p 2222 osboxes@localhost -t "cd memtier_benchmark ; ./memtier_benchmark -p 1234 --requests=1000 --protocol=memcache_text --clients=1 --run-count=1 --threads=1 --debug --key-maximum=10000 --expiry-range=9999-10000 --ratio=1:0 --data-size=4096"
start cmd /k ssh -p 2222 osboxes@localhost -t "cd memtier_benchmark ; ./memtier_benchmark -p 1234 --requests=10 --protocol=memcache_text --clients=1 --run-count=1 --threads=1 --debug --key-maximum=10 --expiry-range=9999-10000 --ratio=1:10 --data-size=4096 --multi-key-get=10 ; /bin/bash"
