# virtualbox
start as headless
connect via ssh (using putty or):
ssh junkerp@localhost:2222


Username: osboxes
Password: osboxes.org

# memtier
./memtier_benchmark -p 1234 -n 1 --protocol=memcache_text -c 1 -x 1 -t 1

# memcached
memcached -p 11212 -vv &
-vv logs all incoming and outgoing requests

# middleware
ant jar
java -jar dist/middleware-junkerp.jar -l localhost -p 1234 -t 1 -s false -m localhost:11212