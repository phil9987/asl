#!/bin/bash
source variables.sh
source helperFunctions.sh

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2

echo "starting MW1"
startMiddleware1 3 1 ${NONSHARDED}
echo "MW1 started"
memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW1"
stopAllMW1
echo "starting MW2"
startMiddleware2 3 1 ${NONSHARDED}
echo "MW2 started"
memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=1000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
echo "stopping MW2"
stopAllMW2