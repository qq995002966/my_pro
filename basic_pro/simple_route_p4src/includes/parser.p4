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


parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}


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


#define IP_PROTOCOLS_TCP  0x6

parser parse_ipv4 {
    extract(ipv4);
	set_metadata(tcp_checksum_metadata.tcpLength,ipv4.totalLen - 20);
    return select(latest.protocol){
		IP_PROTOCOLS_TCP : parser_tcp;
		default:ingress;
	}
}

parser parser_tcp{
	extract(tcp);
	set_metadata(metadata_vcc_tcp_window.tcp_window,latest.window);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
						(tcp.dataOffset*4)-20);
	/*return ingress;//这里是为了测试 tcp dataOffset字段*/
	return select(tcp.dataOffset){
		0x5 : ingress;		//5代表没有tcp options
		default:parser_tcp_options;
	}
}
parser parser_tcp_options{
	return select(metadata_vcc_tcp_window.tcp_options_len_left,
		current(0,8)){
		0x000000 mask 0xffff00 : ingress;
		0x000000 mask 0x0000ff : parser_tcp_options_EOL;
		0x000001 mask 0x0000ff : parser_tcp_options_NOP;
		0x000002 mask 0x0000ff : parser_tcp_options_MSS;
		0x000003 mask 0x0000ff : parser_tcp_options_WINDOW;
		0x000004 mask 0x0000ff : parser_tcp_options_SACK_PERM;
		0x000005 mask 0x0000ff : parser_tcp_options_SACK;
		0x000008 mask 0x0000ff : parser_tcp_options_TIMESTAMP;
		0x000013 mask 0x0000ff : parser_tcp_options_MD5SIG;
	}
}

parser parser_tcp_options_EOL{
	extract(tcp_option_EOL);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-1);
	return parser_tcp_options;
}

parser parser_tcp_options_NOP{
	extract(tcp_option_NOP[next]);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-1);
	return parser_tcp_options;
}

parser parser_tcp_options_MSS{
	extract(tcp_option_MSS);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-4);
	return parser_tcp_options;
}

parser parser_tcp_options_WINDOW{
	extract(tcp_option_WINDOW);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-3);
	return parser_tcp_options;
}
parser parser_tcp_options_SACK_PERM{
	extract(tcp_option_SACK_PERM);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-2);
	return parser_tcp_options;
}

parser parser_tcp_options_SACK{
	extract(tcp_option_SACK);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-tcp_option_SACK.len);
	return parser_tcp_options;
}

parser parser_tcp_options_TIMESTAMP{
	extract(tcp_option_TIMESTAMP);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-10);
	return parser_tcp_options;
}

parser parser_tcp_options_MD5SIG{
	extract(tcp_option_MD5SIG);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
		metadata_vcc_tcp_window.tcp_options_len_left-18);
	return parser_tcp_options;
}
/*******************************************************/
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
