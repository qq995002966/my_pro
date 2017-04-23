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
		tcp_window:16;//用来记录tcp。window事实证明，不许也这个东西也行
		tcp_options_len_left:16;
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
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
						tcp.dataOffset/4-20);
	return select(tcp.dataOffset){
		80 : ingress;//80代表没有tcp options
		default:parser_tcp_options_kind;
	}
}
header tcp_options_kind_t tcp_options_kind;
parser parser_tcp_options_kind{
	extract(tcp_options_kind);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
				metadata_vcc_tcp_window.tcp_options_len_left-1);

	return select(metadata_vcc_tcp_window.tcp_options_len_left,//16 bit
					tcp_options_kind.kind){//8bit
		//如果剩余的options字节长度为0，ingress
		0x000000 mask 0xffff00:ingress;
		//不为0，那么要看 tcp_options_kind.kind 的值
		//tcp_options_kind.kind为 1,parser_tcp_options_kind
		0x000001 mask 0x0000ff:parser_tcp_options_kind;
		// 为10 ,是需要的那个 sw option，parser_tcp_options_sw,然后就进入ingress就行了
		0x00000a mask 0x0000ff:parser_tcp_options_sw;
		//其他的值也就是default，只解析出来长度，然后根据长度跳过
		//不需要的这些数据即可,parser_tcp_options_length
		default:parser_tcp_options_length;
	}
}

header tcp_options_length_t tcp_options_length;
parser parser_tcp_options_length{
	extract(tcp_options_length);
	set_metadata(metadata_vcc_tcp_window.tcp_options_len_left,
				metadata_vcc_tcp_window.tcp_options_len_left - tcp_options_length.len - 1);
	//由于p4的局限性，这里只能使用比较笨的方法，把不需要的tcp options的值
	//解析出来扔掉。
	//这里参照了 include/net/tcp.h 中的那几种TCP options length，分别为
	// 2、3、4、6、10、18

	//不过要注意，如果tcp_options_len_left为0的话，就不需要再继续解析下去了
	return select(metadata_vcc_tcp_window.tcp_options_len_left,//16bit 
							tcp_options_length.len){//8 bit 
		//metadata_vcc_tcp_window.tcp_options_len_lef为0，ingress
		0x000000 mask 0xffff00:ingress;
		//metadata_vcc_tcp_window.tcp_options_len_lef不为0
		//这是要看tcp_options_length.len的值
		0x000002 mask 0x0000ff:parser_tcp_options_kind;
		0x000003 mask 0x0000ff:parser_rubbish_3;
		0x000004 mask 0x0000ff:parser_rubbish_4;
		0x000006 mask 0x0000ff:parser_rubbish_6;
		0x0000010 mask 0x0000ff:parser_rubbish_10;
		0x0000018 mask 0x0000ff:parser_rubbish_18;

		default:ingress;
	}
}

header tcp_options_sw_len_value_t tcp_options_sw_len_value;
parser parser_tcp_options_sw{
	extract(tcp_options_sw_len_value);
	return ingress;//如果能够解析出来sw options，那么直接进入
					//ingress 就行了
}

header tcp_options_rubbish_3_t tcp_options_rubbish_3;
parser parser_rubbish_3{
	extract(tcp_options_rubbish_3);
	return parser_tcp_options_kind;
}

header tcp_options_rubbish_4_t tcp_options_rubbish_4;
parser parser_rubbish_4{
	extract(tcp_options_rubbish_4);
	return parser_tcp_options_kind;
}
header tcp_options_rubbish_6_t tcp_options_rubbish_6;
parser parser_rubbish_6{
	extract(tcp_options_rubbish_6);
	return parser_tcp_options_kind;
}
header tcp_options_rubbish_10_t tcp_options_rubbish_10;
parser parser_rubbish_10{
	extract(tcp_options_rubbish_10);
	return parser_tcp_options_kind;
}
header tcp_options_rubbish_18_t tcp_options_rubbish_18;
parser parser_rubbish_18{
	extract(tcp_options_rubbish_18);
	return parser_tcp_options_kind;
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
