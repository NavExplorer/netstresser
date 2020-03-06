#!/bin/bash
datadir=$(mktemp -d)
/home/cluster/aguycalled/navcoin-core/src/qt/navcoin-qt -devnet -dandelion=0 -disablesafemode -ntpminmeasures=0 -datadir=$datadir -port=10000&
