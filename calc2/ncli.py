#!/usr/bin/env python

from scapy.all import sendp, srp1
from scapy.all import Packet
from scapy.all import Ether, StrFixedLenField, XByteField, IntField
from scapy.all import bind_layers

ETHER_TYPE = 0x1234

class P4calc(Packet):
    name = "P4calc"
    fields_desc = [XByteField("version", 0x01),
                   StrFixedLenField("op", "X", length=1),
                   IntField("id", 0),
                   IntField("data", 0xDEADBABE)]

bind_layers(Ether, P4calc, type=ETHER_TYPE)


IFACE = 'eth0'
DST = '00:04:00:00:00:00'

def command_put(data):
    try:
        pkt = Ether(dst=DST, type=ETHER_TYPE) / P4calc(op='+', id=0, data=int(data))

        resp = srp1(pkt, iface=IFACE, timeout=1, verbose=False)
        if resp:
            p4calc = resp[P4calc]
            if p4calc:
                print("ID: {}".format(p4calc.id))
            else:
                print("cannot find P4calc header in the packet")
        else:
            print("Didn't receive response")
    except Exception as error:
        print(error)

def command_get(key_id):
    try:
        pkt = Ether(dst=DST, type=ETHER_TYPE) / P4calc(op='-', id=int(key_id), data=0)

        resp = srp1(pkt, iface=IFACE, timeout=1, verbose=False)
        if resp:
            p4calc = resp[P4calc]
            if p4calc:
                print("Value: {}".format(p4calc.data))
            else:
                print("cannot find P4calc header in the packet")
        else:
            print("Didn't receive response")
    except Exception as error:
        print(error)

def command_rm(key_id):
    try:
        pkt = Ether(dst=DST, type=ETHER_TYPE) / P4calc(op='*', id=int(key_id), data=0)

        sendp(pkt, iface=IFACE, verbose=False)
    except Exception as error:
        print(error)


def main():

    while True:
        user_input = str(raw_input('> '))
        argv = user_input.split()
        if len(argv) > 0:
            command = argv[0]
        else:
            print("no command")
            continue

        if command in ("quit", "exit"):
            break

        if command == "put":
            try:
                if int.bit_length(int(argv[1])) <= 32:
                    data = argv[1]
            except Exception as error:
                print(error)
                continue

            command_put(data)
        elif command == "get":
            if len(argv) != 2:
                print("incorrect arguments, please use the following format:")
                print("get <key_id>")
                continue

            command_get(argv[1])
        elif command == "rm":
            if len(argv) != 2:
                print("incorrect arguments, please use the following format:")
                print("rm <key_id>")
                continue

            command_rm(argv[1])
        else:
            print("Unknown command: " + command)


if __name__ == '__main__':
    main()
