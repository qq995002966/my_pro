BMV2_PATH=/home/mininet/documents/p4lang/behavioral-model

P4C_BM_PATH=/home/mininet/documents/p4lang/p4c-bm

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch
ROUTER_PATH=$BMV2_PATH/targets/simple_router/simple_router

CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py
$P4C_BM_SCRIPT p4src/simple_router.p4 --json simple_router.json

sudo python $BMV2_PATH/mininet/1sw_demo.py \
      --behavioral-exe $ROUTER_PATH \
      --json simple_router.json
