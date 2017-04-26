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


/*******************************************************/

table simple_ecn {
		//可能这个地方用 register语义上更合适
	reads{
		ipv4.ecn:exact;
	}
	actions{
		set_ece;
		set_tcp_window;
		_drop;
	}
	size:512;
}


action set_tcp_window(){
	modify_field(tcp.window,(tcp.window*3)/4);
}

action set_ece(){
	modify_field(ipv4.ecn,3);
}
/*使用寄存器实现vcc逻辑*******************************/
/*在ingress 控制流中存储每个端口的数据包的窗口值大小到对应的
register中*/
register register_vcc{
	width:16;
	instance_count:128;
}
/*在egress中设置如果出去的端口值为1，那么将其window设置成为
其他的2~11端口对应的寄存器的平均值*/
/********************************************/
// TCP OPTIONS
table table_store_tcp_info{
	actions{
		action_store_tcp_info;
	}
}

action action_store_tcp_info(){
	register_write(register_vcc,22,tcp.dataOffset);
	register_write(register_vcc,23,metadata_vcc_tcp_window.tcp_options_len_left);
}
/********************************************/
//为了调整tcp options的位置，使其满足 对齐
/********************************************/
control ingress {
    apply(ipv4_lpm);
    apply(forward);
	
	if(standard_metadata.ingress_port==3){
		apply(table_store_tcp_info);
	}
}

control egress {
    apply(send_frame);
	if(queueing_metadata.enq_qdepth>=3){
		apply(simple_ecn);//如果用register实现vcc的话，
				//这里的对应的commands.txt中的表项就不能有_drop
				//也不能有 set_tcp_window了
	}
	
}
