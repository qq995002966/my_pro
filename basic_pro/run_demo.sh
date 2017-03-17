BMV2_PATH=/home/mininet/documents/p4lang/behavioral-model

P4C_BM_PATH=/home/mininet/documents/p4lang/p4c-bm

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch

CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py
$P4C_BM_SCRIPT p4src/simple_router.p4 --json simple_router.json
# $P4C_BM_SCRIPT p4src/testQueue/queueing.p4 --json simple_router.json

# TOPO_PATH=$BMV2_PATH/mininet/1sw_demo.py
TOPO_PATH=$BMV2_PATH/mininet/figure4.py

sudo python $TOPO_PATH\
      --behavioral-exe $SWITCH_PATH \
      --json simple_router.json

