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

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 6;
		ecn : 2 ;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type tcp_t {
	fields {
		srcPort : 16;
		dstPort : 16;
		seqNo : 32;
		ackNo : 32;
		dataOffset : 4;
		res : 3;
		ecn : 3;
		URG:1;
		ACK:1;
		PSH:1;
		RST:1;
		SYN:1;
		FIN:1;
		window : 16;
		checksum : 16;
		urgentPtr : 16;
	}
}

header_type tcp_checksum_metadata_t {
	fields {
		tcpLength : 16;
	}
}

header_type metadata_vcc_tcp_window_t{
	fields{
		tcp_window:16;//用来记录tcp。window事实证明，不许也这个东西也行
		tcp_options_len_left:16;
	}
}

register register_vcc{
	width:16;
	instance_count:128;
}

header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
    }
}


header_type queueing_metadata_t {
  fields {
    enq_timestamp: 48;
    enq_qdepth: 16;
    deq_timedelta: 32;
    deq_qdepth: 16;
  }
}

header_type tcp_option_EOL_T{
	fields{
		kind:8;//0
	}
}

header_type tcp_option_NOP_t{
	fields{
		kind:8;//1
	}
}

/*header_type tcp_option_MSS_t{*/
	/*fields{*/
		/*kind:8;//2*/
		/*len:8;*/
		/*value:16;*/
	/*}*/
/*}*/

/*header_type tcp_option_WINDOW_t{*/
	/*fields{*/
		/*kind:8;//3*/
		/*len:8;*/
		/*value:8;*/
	/*}*/
/*}*/

header_type tcp_option_SACK_PERM_t{
	fields{
		kind:8;//4
		len:8;
	}
}

header_type tcp_option_SACK_t{
	fields{
		kind:8;//5
		len:8;//
		value:*;
	}
	length:len;
	max_length:40;
}

header_type tcp_option_TIMESTAMP_t{
	fields{
		kind:8;//8
		len:8;
		value:64;
	}
}

/*header_type tcp_option_MD5SIG_t{*/
	/*fields{*/
		/*kind:8;//19*/
		/*len:8;*/
		/*value:128;*/
	/*}*/
/*}*/


header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;
header tcp_option_EOL_T tcp_option_EOL;
header tcp_option_NOP_t tcp_option_NOP[9];
/*header tcp_option_MSS_t tcp_option_MSS;*/
/*header tcp_option_WINDOW_t tcp_option_WINDOW;*/
header tcp_option_SACK_PERM_t tcp_option_SACK_PERM;
header tcp_option_SACK_t tcp_option_SACK;
header tcp_option_TIMESTAMP_t tcp_option_TIMESTAMP;
/*header tcp_option_MD5SIG_t tcp_option_MD5SIG;*/

metadata tcp_checksum_metadata_t tcp_checksum_metadata;
metadata metadata_vcc_tcp_window_t metadata_vcc_tcp_window;
metadata routing_metadata_t routing_metadata;
metadata queueing_metadata_t queueing_metadata;

@pragma header_ordering ethernet ipv4 tcp tcp_option_NOP tcp_option_SACK_PERM tcp_option_SACK tcp_option_TIMESTAMP
