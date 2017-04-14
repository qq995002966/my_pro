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

header_type test_registers_metadata_t{
	fields{
		register_tmp:16;
	}
}

metadata test_registers_metadata_t test_registers_metadata;

register test_registers{
	width:16;
	instance_count:128;
}
header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
    }
}

metadata routing_metadata_t routing_metadata;

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

action modify_ttl_with_register(){
	register_read(test_registers_metadata.register_tmp,test_registers,0);
	modify_field(ipv4.ttl,test_registers_metadata.register_tmp);
}

table table_modify_ttl_with_register{
	actions{
		modify_ttl_with_register;
	}
}

control ingress {
    apply(ipv4_lpm);
    apply(forward);
	apply(table_test_write_register);
}

control egress {//这个egress是在哪里起作用的呀?这难道也是关键字么?
    apply(send_frame);
	apply(table_modify_ttl_with_register);
}

/*为了测试写寄存器*/
table table_test_write_register{
	actions{
		action_test_write_register;
	}
}

action action_test_write_register(){
	register_write(test_registers,1,ipv4.ttl);
}
