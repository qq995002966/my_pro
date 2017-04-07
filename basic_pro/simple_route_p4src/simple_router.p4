/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "includes/headers.p4"
#include "includes/parser.p4"

action _drop() {
    drop();
}

header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
    }
}

metadata routing_metadata_t routing_metadata;

header_type queueing_metadata_t {
  fields {
    enq_timestamp: 48;

    enq_qdepth: 16;

    deq_timedelta: 32;

    deq_qdepth: 16;

  }
}

metadata queueing_metadata_t queueing_metadata;

action set_nhop(nhop_ipv4, port) {
    modify_field(routing_metadata.nhop_ipv4, nhop_ipv4);
    modify_field(standard_metadata.egress_spec, port);
    add_to_field(ipv4.ttl, -1);
}

table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_nhop;
        _drop;
    }
    size: 1024;
}

action set_dmac(dmac) {
    modify_field(ethernet.dstAddr, dmac);
}

table forward {
    reads {
        routing_metadata.nhop_ipv4 : exact;
    }
    actions {
        set_dmac;
        _drop;
    }
    size: 512;
}

action rewrite_mac(smac) {
    modify_field(ethernet.srcAddr, smac);
}

table send_frame {
    reads {
        standard_metadata.egress_port: exact;
    }
    actions {
        rewrite_mac;
        _drop;
    }
    size: 256;
}

control ingress {
    apply(ipv4_lpm);
    apply(forward);
}

control egress {//这个egress是在哪里起作用的呀?这难道也是关键字么?
    apply(send_frame);
	if(queueing_metadata.enq_qdepth>=5){
		apply(simple_ecn);
	}
}

/*******************************************************/

table simple_ecn {//感觉这样写是有问题的,不应该使用一个表这样来实现这个逻辑,
					//但是暂时没想到除了这个方法应该怎么弄,暂时先姑且这样吧.
	reads{
		ipv4.ecn:exact;
	}
	actions{
		set_ece;
		set_vcc;
		_drop;
	}
	size:512;
}

action set_vcc(){
	//只是为了实现特别简单的vcc逻辑，
	//就单单把TCP数据包的接收窗口减半试试
	//但是在实现这个逻辑之前需要修改parser.p4让交换机能够支持
	//TCP协议
	modify_field(tcp.window,tcp.window/2);
}

action set_ece(){
	modify_field(ipv4.ecn,3);
}
