#!/bin/bash
rm -rf ~/.navcoin4/devnet
/home/cluster/aguycalled/navcoin-core/src/navcoind -devnet -dandelion=0 -disablesafemode -ntpminmeasures=0 -addnode=127.0.0.1:10000 -daemon
sleep 10
out=$(/home/cluster/aguycalled/navcoin-core/src/navcoin-cli -devnet generate 301)
