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
table table_vcc_store_windows{
	actions{
		action_vcc_store_windows;
	}
}
action action_vcc_store_windows(){
	register_write(register_vcc,standard_metadata.ingress_port,
	tcp_options_sw_len_value.snd_cwnd);
	/*register_write(register_vcc,standard_metadata.egress_spec,*/
	/*tcp.window);*/
	/*register_write(register_vcc,standard_metadata.ingress_port,*/
	/*ipv4.totalLen);*/
}
/*在egress中设置如果出去的端口值为1，那么将其window设置成为
其他的2~11端口对应的寄存器的平均值*/
header_type metadata_vcc_register_temp_t{
	fields{
		register_temp1:16;
		register_temp2:16;
		register_temp3:16;
		register_temp4:16;
		register_temp5:16;
		register_temp6:16;
		register_temp7:16;
		register_temp8:16;
		register_temp9:16;
		register_temp10:16;
		register_temp11:16;
	}
}
metadata metadata_vcc_register_temp_t metadata_vcc_register_temp;
table table_vcc_set_window{
	actions{
		action_vcc_set_window;
		action_test_vcc;
	}
}
action action_vcc_set_window(){
	register_read(metadata_vcc_register_temp.register_temp2,register_vcc,2);
	register_read(metadata_vcc_register_temp.register_temp3,register_vcc,3);
	register_read(metadata_vcc_register_temp.register_temp4,register_vcc,4);
	register_read(metadata_vcc_register_temp.register_temp5,register_vcc,5);
	register_read(metadata_vcc_register_temp.register_temp6,register_vcc,6);
	register_read(metadata_vcc_register_temp.register_temp7,register_vcc,7);
	register_read(metadata_vcc_register_temp.register_temp8,register_vcc,8);
	register_read(metadata_vcc_register_temp.register_temp9,register_vcc,9);
	register_read(metadata_vcc_register_temp.register_temp10,register_vcc,10);
	register_read(metadata_vcc_register_temp.register_temp11,register_vcc,11);

	modify_field(tcp.window,( 
								metadata_vcc_register_temp.register_temp3+
								metadata_vcc_register_temp.register_temp4+
								metadata_vcc_register_temp.register_temp5+
								metadata_vcc_register_temp.register_temp6+
								metadata_vcc_register_temp.register_temp7+
								metadata_vcc_register_temp.register_temp8+
								metadata_vcc_register_temp.register_temp9+
								metadata_vcc_register_temp.register_temp10+
								metadata_vcc_register_temp.register_temp11
								)/9);
	register_write(register_vcc,100,tcp.window);
	/*register_write(register_vcc,100,(*/
								/*metadata_vcc_register_temp.register_temp3+*/
								/*metadata_vcc_register_temp.register_temp4+*/
								/*metadata_vcc_register_temp.register_temp5+*/
								/*metadata_vcc_register_temp.register_temp6+*/
								/*metadata_vcc_register_temp.register_temp7+*/
								/*metadata_vcc_register_temp.register_temp8+*/
								/*metadata_vcc_register_temp.register_temp9+*/
								/*metadata_vcc_register_temp.register_temp10+*/
								/*metadata_vcc_register_temp.register_temp11*/
								/*)/9*/
								/*);*/
}

action action_test_vcc(){
	modify_field(tcp.window,10);
}
/********************************************/
// TCP OPTIONS
table table_store_tcp_dataoff{
	actions{
		action_store_tcp_dataoff;
	}
}
action action_store_tcp_dataoff(){
	register_write(register_vcc,22,tcp.dataOffset);
	register_write(register_vcc,23,metadata_vcc_tcp_window.tcp_options_len_left);
}

/********************************************/
control ingress {
    apply(ipv4_lpm);
    apply(forward);
	
	apply(table_vcc_store_windows);
	apply(table_store_tcp_dataoff);
}

control egress {
    apply(send_frame);
	if(queueing_metadata.enq_qdepth>=3){
		apply(simple_ecn);//如果用register实现vcc的话，
				//这里的对应的commands.txt中的表项就不能有_drop
				//也不能有 set_tcp_window了
	}

	if(standard_metadata.egress_spec==2){
		apply(table_vcc_set_window);
	}
}
