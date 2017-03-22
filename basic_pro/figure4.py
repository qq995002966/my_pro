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

from mininet.link import TCLink, TCIntf, Link
from mininet.topo import Topo
import termcolor as T

# Just for some fancy color printing
def cprint(s, color, cr=True):
    """Print in color
       s: string to print
       color: color to use"""
    if cr:
        print T.colored(s, color)
    else:
        print T.colored(s, color),


class Figure4Topo(Topo):
    "figure4Toto with 10 host on the left connected to a simpe_switch(p4) "

    def __init__(self, n=3, cpu=None, bw_host=None, bw_net=None,
                 delay=None, maxq=None, enable_ecn=None, enable_red=None,
                 show_mininet_commands=False, red_params=None):
        # Add default members to class.
        super(Figure4Topo, self ).__init__()
        self.n = n
        self.cpu = cpu
        self.bw_host = bw_host
        self.bw_net = bw_net
        self.delay = delay
        self.maxq = maxq
        self.enable_ecn = enable_ecn
        self.enable_red = enable_red
        self.red_params = red_params
        self.show_mininet_commands = show_mininet_commands;

        cprint("Enable ECN: %d" % self.enable_ecn, 'green')
        cprint("Enable RED: %d" % self.enable_red, 'green')

        self.create_topology()

    # Create the experiment topology
    # Set appropriate values for bandwidth, delay,
    # and queue size
    def create_topology(self):
        # Host and link configuration
        hconfig = {'cpu': self.cpu}


	# Set configurations for the topology and then add hosts etc.
        lconfig_sender = {'bw': self.bw_host, 'delay': self.delay,
                          'max_queue_size': self.maxq,
                          'show_commands': self.show_mininet_commands}
        lconfig_receiver = {'bw': self.bw_net, 'delay': self.delay,
                            'max_queue_size': self.maxq,
                            'show_commands': self.show_mininet_commands}
        lconfig_switch = {'bw': self.bw_net, 'delay': self.delay,
                            'max_queue_size': self.maxq,
                            'enable_ecn': 1 if self.enable_ecn else 0,
                            'enable_red': 1 if self.enable_red else 0,
                            'red_params': self.red_params if ( (self.enable_red )
                            and self.red_params != None) else None,
                            'show_commands': self.show_mininet_commands}

        n = self.n
        # Create the receiver
        receiver = self.addHost('h0',
                                mac='00:04:00:00:00:01')
        #crate a switch
        sw_path=" /home/mininet/documents/p4lang/behavioral-model/targets/simple_switch/simple_switch"
        json_path="simple_router.json"
        switch = self.addSwitch('s0',
                                sw_path=sw_path,
                                json_path=json_path,
                                thrift_port=9090,
                                pcap_dump=False
                                )

        #create the sender hosts
        hosts = []
        for h in range(n-1):
            hosts.append(self.addHost('h%d' % (h+1),
                                    mac='00:04:00:00:00:%02x' %(h+2),
                                    ))
                                    # **hconfig))


        # Create links between receiver and switch
        self.addLink(receiver, switch
                     # , cls=Link, cls1=TCIntf, cls2=TCIntf,
                      # params1=lconfig_receiver, params2=lconfig_switch)
                     )


        # Create links between senders and switch
        for i in range(n-1):
	    self.addLink(hosts[i], switch
                  # , **lconfig_sender)
                  )
