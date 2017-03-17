#!/usr/bin/env python2

# created by John 2017/3/16

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.cli import CLI
from mininet.log import setLogLevel

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep

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

    def __init__(self, sw_path, json_path, thrift_port, pcap_dump, sender_count, **opts):
        Topo.__init__(self, **opts)

        #this is left switch
        switch = self.addSwitch('s1',
                                    sw_path=sw_path,
                                    json_path=json_path,
                                    thrift_port=thrift_port,
                                    pcap_dump=pcap_dump)
        #this is right switch

        #this is receiver
        # sender_count senders
        senders=[]
        for h in xrange(sender_count):
            senders.append(self.addHost('sender%d' % h ,
                                        ip="10.0.0.1%d/24" % h))

        receiver = self.addHost('receiver',
                                ip="10.0.1.10/24")
        #

        for h in xrange(sender_count):
            self.addLink(senders[h],switch)

        self.addLink(receiver,switch)


def main():

    topo = figure4Topo(args.behavioral_exe,
                            args.json,
                            args.thrift_port,
                            args.pcap_dump,
                            10)
    net = Mininet(topo=topo,
                  host=P4Host,
                  switch=P4Switch,
                  )
    net.start()


    for n in xrange(10):
        h = net.get('sender%d' % n)
        h.describe()

    receiver=net.get('receiver')
    receiver.describe()

    sleep(1)

    print "Ready !"

    CLI(net)
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    main()
