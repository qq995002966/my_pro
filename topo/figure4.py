#!/usr/bin/env python2

# created by John 2017/3/16

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.cli import CLI
from mininet.log import setLogLevel

from mininet.util import dumpNodeConnections

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep
import subprocess

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--thrift-port', help='Thrift server port for table updates',
                    type=int, action="store", default=9090)
parser.add_argument('--num-hosts', help='Number of hosts to connect to switch',
                    type=int, action="store", default=2)
parser.add_argument('--mode', choices=['l2', 'l3'], type=str, default='l3')
parser.add_argument('--json', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--pcap-dump', help='Dump packets on interfaces to pcap files',
                    type=str, action="store", required=False, default=False)


args = parser.parse_args()


class figure4Topo(Topo):
    "figure4Toto with 10 host on the left connected to a simpe_switch(p4) "

    def __init__(self, sw_path, json_path,
                 thrift_port, pcap_dump, sender_count,
                 senders_sub_name,switch_name,receiver_name,
                 **opts):
        Topo.__init__(self, **opts)

        #this is left switch
        switch = self.addSwitch(switch_name,
                                sw_path=sw_path,
                                json_path=json_path,
                                thrift_port=thrift_port,
                                pcap_dump=pcap_dump)
        #this is receiver
        receiver = self.addHost(receiver_name,
                                mac='00:04:00:00:00:01')
        self.addLink(receiver, switch)

        # sender_count senders
        senders=[]
        for h in range(sender_count):
            senders.append(self.addHost(senders_sub_name+'%d' % (h+1) ,
                                        mac='00:04:00:00:00:%02x' %(h+2)))
#
        for h in range(sender_count):
            self.addLink(senders[h],switch)
#set all senders ecn enable (tcp_ecn = 1)


        #

def enable_senders_ecn(net,sender_count,senders_sub_name,receiver_name):
#set all senders ecn enabled , just for test
    for i in range(sender_count):
        hn=net.getNodeByName(senders_sub_name+'%d' % (i+1))
        hn.popen("sysctl -w net.ipv4.tcp_ecn=1")

    receiver=net.getNodeByName(receiver_name)
    receiver.popen("sysctl -w net.ipv4.tcp_ecn=1")


def set_hosts_default_route_and_arp(net,sender_count,
                                    senders_sub_name,receiver_name):
    for i in range(sender_count):
        sender=net.getNodeByName(senders_sub_name+'%d' % (i+1) )
        sender.setDefaultRoute("dev eth0")
        sender.setARP("10.0.0.1","00:04:00:00:00:01")

    receiver=net.getNodeByName(receiver_name)
    receiver.setDefaultRoute("dev eth0")
    for i in range(sender_count):
        receiver.setARP("10.0.0.%d"%(i+2),"00:04:00:00:00:%02x"%(i+2))


def main():

    sender_count=10
    senders_sub_name="h"
    receiver_name="h0"
    switch_name="s1"
    topo = figure4Topo(args.behavioral_exe,
                       args.json,
                       args.thrift_port,
                       args.pcap_dump,
                       sender_count,
                       senders_sub_name,
                       switch_name,
                       receiver_name)
    net = Mininet(topo=topo,
                  host=P4Host,
                  switch=P4Switch,
                  controller=None)
    net.start()
#display all connections
    dumpNodeConnections(net.hosts)
#enable sender ecn
    enable_senders_ecn(net,sender_count,senders_sub_name,
                       receiver_name)
#set hosts default route
    set_hosts_default_route_and_arp(net,sender_count,
                                    senders_sub_name,receiver_name)
#set hosts default arp


    sleep(1)

    #test auto insert table entries
    subprocess.call(['./add_entries.sh'])
    print("Ready !")

    CLI(net)
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    main()
