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

parser start {//这里这个 parser start应该就是C语言中的入口函数
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

header ipv4_t ipv4;

field_list ipv4_checksum_list {
        ipv4.version;
        ipv4.ihl;
        ipv4.diffserv;
		ipv4.ecn;
        ipv4.totalLen;
        ipv4.identification;
        ipv4.flags;
        ipv4.fragOffset;
        ipv4.ttl;
        ipv4.protocol;
        ipv4.srcAddr;
        ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}


header_type tcp_checksum_metadata_t {
	fields {
		tcpLength : 16;
	}
}

metadata tcp_checksum_metadata_t tcp_checksum_metadata;

header_type metadata_vcc_tcp_window_t{
	fields{
		tcp_window:16;
	}
}
metadata metadata_vcc_tcp_window_t metadata_vcc_tcp_window;

#define IP_PROTOCOLS_TCP  0x6

parser parse_ipv4 {
    extract(ipv4);
	set_metadata(tcp_checksum_metadata.tcpLength,ipv4.totalLen - 20);
    return select(latest.protocol){
		IP_PROTOCOLS_TCP : parser_tcp;
		default:ingress;
	}
}

header tcp_t tcp;
parser parser_tcp{
	extract(tcp);
	set_metadata(metadata_vcc_tcp_window.tcp_window,latest.window);
	return ingress;
}


field_list tcp_checksum_list {
	ipv4.srcAddr;
	ipv4.dstAddr;
	8'0;
	ipv4.protocol;
	tcp_checksum_metadata.tcpLength;
	tcp.srcPort;
	tcp.dstPort;
	tcp.seqNo;
	tcp.ackNo;
	tcp.dataOffset;
	tcp.res;
	tcp.ecn;
	tcp.ctrl;
	tcp.window;
	tcp.urgentPtr;
	payload;
}

field_list_calculation tcp_checksum {
	input {
		tcp_checksum_list;
	}
	algorithm : csum16;
	output_width : 16;
}

calculated_field tcp.checksum {
	    verify tcp_checksum if(valid(tcp));
		update tcp_checksum if(valid(tcp));
}
