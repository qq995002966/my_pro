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
		ctrl : 6;
		window : 16;
		checksum : 16;
		urgentPtr : 16;
	}
}
header_type tcp_options_kind_t{
	fields{
		kind:8;
	}
}
header_type tcp_options_length_t{
	fields{
		len:8;
	}
}

header_type tcp_options_sw_len_value_t{
	fields{
		len:8;
		snd_cwnd:32;
	}
}

//总长度长度是3，数据长度为1，所以这里长度为1字节
header_type tcp_options_rubbish_3_t{
	fields{
		rubbish:8;
	}
}

header_type tcp_options_rubbish_4_t{
	fields{
		rubbish:16;
	}
}
header_type tcp_options_rubbish_6_t{
	fields{
		rubbish:32;
	}
}
header_type tcp_options_rubbish_10_t{
	fields{
		rubbish:64;
	}
}
header_type tcp_options_rubbish_18_t{
	fields{
		rubbish:128;
	}
}
