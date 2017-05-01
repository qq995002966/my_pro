#!/bin/bash

BMV2_PATH=/home/mininet/documents/p4lang/behavioral-model
P4C_BM_PATH=/home/mininet/documents/p4lang/p4c-bm
P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py
SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch
CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py
p4c-bmv2 ./simple_route_p4src/simple_router.p4 --json simple_router.json
#$P4C_BM_SCRIPT ./switch_p4src/switch.p4 --json switch.json

# TOPO_PATH=$BMV2_PATH/mininet/1sw_demo.py
#TOPO_PATH=$BMV2_PATH/mininet/figure4.py
#TOPO_PATH=../topo/figure4.py

#sudo python $TOPO_PATH\
      #--behavioral-exe $SWITCH_PATH \
      #--json simple_router.json

figdir="./figures"
if [ ! -d "$figdir" ]; then
	  mkdir -p $figdir
fi

label="10s"
bw=200
./tcp_fair_RED.sh  ${bw}  ${label}  RED1tab


cd ./tcpfair

#rm -rf $(find|egrep '*.txt|*.out|*.gz|out.wireshark*')
cd ..
tar -cf tcpfair.tar ./tcpfair/

