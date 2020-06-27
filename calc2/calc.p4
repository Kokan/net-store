/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

#define INSTANCE_TYPE_NORMAL 0 
#define INSTANCE_TYPE_I2E_CLONE 1 

/*
 * Define the headers the program will recognize
 */

/*
 * Standard Ethernet header 
 */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the calculator. We'll use 
 * etherType 0x1234 for it (see parser)
 */
const bit<16> NET_STORE_API_ETYPE = 0x1234;
const bit<16> NET_STORE_ETYPE     = 0x1235;
const bit<8>  NET_STORE_VER       = 0x01;   // v0.1
const bit<8>  NET_STORE_PUT       = 0x2b;
const bit<8>  NET_STORE_GET       = 0x2d;
const bit<8>  NET_STORE_RM        = 0x2a;

const bit<32> CLONE_SESSIONID     = 250; /* Keep in sync with netstore_config.txt */

header net_store_api_t {
    bit<8>  ver;
    bit<8>  op;
    bit<32> id;
    bit<32> data;
}

header net_store_t {
   bit<8>  ver;
   bit<32> id;
   bit<32> data;
};

/*
 * All headers, used in the program needs to be assembled into a single struct.
 * We only need to declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
struct headers {
    ethernet_t      ethernet;
    net_store_api_t net_store_api;
    net_store_t     net_store;
}

/*
 * All metadata, globally used in the program, also  needs to be assembled 
 * into a single struct. As in the case of the headers, we only need to 
 * declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
 
struct metadata {
    /* In our case it is empty */
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {    
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            NET_STORE_API_ETYPE : check_net_store_api;
            NET_STORE_ETYPE     : check_net_store;
            default             : accept;
        }
    }
    
    state check_net_store_api {
        transition select(packet.lookahead<net_store_api_t>().ver) {
            NET_STORE_VER : parse_net_store_api;
            default       : accept;
        }
    }
    
    state parse_net_store_api {
        packet.extract(hdr.net_store_api);
        transition accept;
    }
    
    state check_net_store {
        transition select(packet.lookahead<net_store_t>().ver) {
            NET_STORE_VER : parse_net_store;
            default       : accept;
        }
    }
    
    state parse_net_store {
        packet.extract(hdr.net_store);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    register<bit<32>>(1) reg;

    register<bit<32>>(1) rm_reg;

    bool marked_to_circulate = false;

    action operation_forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }

    
    action operation_get() {
        @atomic {
          reg.write(0,hdr.net_store_api.id);
        }
    }

    action operation_rm() {
        @atomic {
          rm_reg.write(0,hdr.net_store_api.id);
        }
    }

    action operation_drop() {
        mark_to_drop(standard_metadata);
    }
    

    table net_store_lpm {
        key = {
           standard_metadata.ingress_port : exact;
        }
        actions = {
            operation_forward;
            operation_drop;
            NoAction;
        }
        size = 1024;
        const default_action = operation_drop();
    }

    action operation_put() {
        marked_to_circulate = true;

        hdr.net_store.setValid();
        hdr.net_store_api.setInvalid();   
        
        hdr.ethernet.etherType = NET_STORE_ETYPE;
        hdr.net_store.ver   = NET_STORE_VER;
        hdr.net_store.id    = hdr.net_store_api.id;
        hdr.net_store.data  = hdr.net_store_api.data; 

        clone(CloneType.I2E, CLONE_SESSIONID);
    }

    table calculate {
        key = {
            hdr.net_store_api.op        : exact;
        }
        actions = {
            operation_put;
            operation_get;
            operation_rm;
            operation_drop;
        }
        const default_action = operation_drop();
        const entries = {
            NET_STORE_PUT : operation_put();
            NET_STORE_GET : operation_get();
            NET_STORE_RM  : operation_rm();
        }
    }

    action net_store_handle_request() {
        marked_to_circulate = true;
        clone(CloneType.I2E, CLONE_SESSIONID);
    }

    apply {

       bit<32> hash_id;
       if (hdr.net_store_api.isValid() && hdr.net_store_api.data != 0) {
           hash(hash_id,
                HashAlgorithm.crc16,
                (bit<32>)1,
                {hdr.net_store_api.data},
                (bit<32>)1000);

           hdr.net_store_api.id  = hash_id;
           hdr.net_store.id  = hash_id;
       }

       if (hdr.net_store.isValid() && hdr.net_store.data != 0) {
           hash(hash_id,
                HashAlgorithm.crc16,
                (bit<32>)1,
                {hdr.net_store.data},
                (bit<32>)1000);

           hdr.net_store_api.id  = hash_id;
           hdr.net_store.id  = hash_id;
        }

        if (hdr.net_store.isValid()) {
            bit<32> id;
            @atomic {
              reg.read(id,0);
            }

            bit<32> rm_id;
            @atomic {
               rm_reg.read(rm_id,0);
            }

            if(id == hdr.net_store.id)
            {
                net_store_handle_request();
                @atomic {
                  reg.write(0,0);
                }
            }
            else if(rm_id == hdr.net_store.id)
            {
                mark_to_drop(standard_metadata);

                @atomic {
                  rm_reg.write(0,0);
                }
            }
            else
            { 
                marked_to_circulate = true;
            }
        } else if (hdr.net_store_api.isValid()) {
            calculate.apply();
        } else {
            operation_drop();
        }

        if(marked_to_circulate)
        {
            net_store_lpm.apply();
        }
    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    apply {

       bit<32> hash_id;
       if (hdr.net_store_api.isValid() && hdr.net_store_api.data != 0) {
           hash(hash_id,
                HashAlgorithm.crc16,
                (bit<32>)1,
                {hdr.net_store_api.data},
                (bit<32>)1000);

           hdr.net_store_api.id  = hash_id;
           hdr.net_store.id  = hash_id;
       }

       if (hdr.net_store.isValid() && hdr.net_store.data != 0) {
           hash(hash_id,
                HashAlgorithm.crc16,
                (bit<32>)1,
                {hdr.net_store.data},
                (bit<32>)1000);

           hdr.net_store_api.id  = hash_id;
           hdr.net_store.id  = hash_id;
        }

        if (standard_metadata.instance_type == INSTANCE_TYPE_I2E_CLONE) {

            hdr.net_store.setInvalid();
            hdr.net_store_api.setValid();
            hdr.ethernet.etherType = NET_STORE_API_ETYPE;

            if(hdr.net_store_api.op != NET_STORE_PUT)
            {
                hdr.net_store_api.ver  = NET_STORE_VER;
                hdr.net_store_api.op   = NET_STORE_GET;
                hdr.net_store_api.id   = hdr.net_store.id;
                hdr.net_store_api.data = hdr.net_store.data;                 
            }
 
        }

     }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
 ***********************  D E P A R S E R  *******************************
 *************************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.net_store_api);
        packet.emit(hdr.net_store);
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
