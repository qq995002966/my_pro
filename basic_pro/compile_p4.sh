#!/bin/bash

BMV2_PATH=/home/mininet/documents/p4lang/behavioral-model
P4C_BM_PATH=/home/mininet/documents/p4lang/p4c-bm
P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py
SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch
CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py

$P4C_BM_SCRIPT ./simple_route_p4src/simple_router.p4 --json simple_router.json
