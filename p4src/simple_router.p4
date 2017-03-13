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


header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 4;
        egress_rid : 4;
        mcast_hash : 16;
        lf_field_list: 32;
        ingress_global_timestamp : 64;
        resubmit_flag : 16;
        recirculate_flag : 16;
    }
}

metadata intrinsic_metadata_t intrinsic_metadata;

header_type queueing_metadata_t {
       fields {
           enq_timestamp : 48;
           enq_qdepth : 16;
           deq_timedelta : 32;
           deq_qdepth : 16;
       }
   }
  
metadata queueing_metadata_t queueing_metadata;
header queueing_metadata_t queueing_hdr;

action set_nhop(nhop_ipv4, port) {
    modify_field(routing_metadata.nhop_ipv4, nhop_ipv4);
    modify_field(standard_metadata.egress_spec, port);
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
    modify_field(ipv4.ttl,0);
    //有
    /* add_to_field(ipv4.ttl,queueing_metadata.enq_timestamp); */
    //没
    add_to_field(ipv4.ttl,queueing_metadata.enq_qdepth);
    //有
    /* add_to_field(ipv4.ttl,queueing_metadata.deq_timedelta); */
    //没
    /* add_to_field(ipv4.ttl,queueing_metadata.deq_qdepth); */
    //没
    /* add_to_field(ipv4.ttl, intrinsic_metadata.mcast_grp); */
    //没
    /* add_to_field(ipv4.ttl, intrinsic_metadata.egress_rid); */
    //没
    /* add_to_field(ipv4.ttl, intrinsic_metadata.mcast_hash); */
    //没
    /* add_to_field(ipv4.ttl, intrinsic_metadata.lf_field_list); */
    //有
    /* add_to_field(ipv4.ttl, intrinsic_metadata.ingress_global_timestamp); */
    //没
    /* add_to_field(ipv4.ttl, intrinsic_metadata.resubmit_flag); */
    //没
    /* add_to_field(ipv4.ttl, intrinsic_metadata.recirculate_flag); */



    /* add_header(queueing_hdr); */
    /* modify_field(queueing_hdr.enq_timestamp, queueing_metadata.enq_timestamp); */
    /* modify_field(queueing_hdr.enq_qdepth, queueing_metadata.enq_qdepth); */
    /* modify_field(queueing_hdr.deq_timedelta, queueing_metadata.deq_timedelta); */
    /* modify_field(queueing_hdr.deq_qdepth, queueing_metadata.deq_qdepth); */

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
}


