#!/usr/bin/env python

import argparse
import sys
import socket
import random
import struct
import re

from scapy.all import sendp, send, srp1
from scapy.all import Packet, hexdump
from scapy.all import Ether, StrFixedLenField, XByteField, IntField
from scapy.all import bind_layers
import readline

ETHER_TYPE = 0x1234

class P4calc(Packet):
    name = "P4calc"
    fields_desc = [ XByteField("version", 0x01),
                    StrFixedLenField("op", "X", length=1),
                    IntField("id", 0),
                    IntField("data", 0xDEADBABE)]

bind_layers(Ether, P4calc, type=ETHER_TYPE)


iface = 'eth0'
dst = '00:04:00:00:00:00'

def command_put(data):
    try:
        pkt = Ether(dst=dst, type=ETHER_TYPE) / P4calc(op='+',
                                          id=0,
                                          data=int(data))

        resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
        if resp:
            p4calc=resp[P4calc]
            if p4calc:
                print "ID: {}".format(p4calc.id)
            else:
                print "cannot find P4calc header in the packet"
        else:
            print "Didn't receive response"
    except Exception as error:
        print error

def command_get(id):
    try:
        pkt = Ether(dst=dst, type=ETHER_TYPE) / P4calc(op='-',
                                          id=int(id),
                                          data=0)

        resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
        if resp:
            p4calc=resp[P4calc]
            if p4calc:
                print "Value: {}".format(p4calc.data)
            else:
                print "cannot find P4calc header in the packet"
        else:
            print "Didn't receive response"
    except Exception as error:
        print error

def command_rm(id):
    try:
        pkt = Ether(dst=dst, type=ETHER_TYPE) / P4calc(op='*',
                                          id=int(id),
                                          data=0)

        sendp(pkt, iface=iface, verbose=False)
    except Exception as error:
        print error


def main():

    while True:
        s = str(raw_input('> '))
        argv = s.split()
        if len(argv) > 0:
           command = argv[0]
        else:
           print "no command"
           continue

        if command == "quit" or command == "exit":
           break
        elif command == "put":
           try:
               if int.bit_length(int(argv[1])) <= 32:
                   data = argv[1]
           except Exception as error:
               print error
               continue

           command_put(data)
        elif command == "get":
           if len(argv) != 2:
              print "incorrect arguments, please use the following format:"
              print "get <id>"
              continue

           command_get(argv[1])
        elif command == "rm":
           if len(argv) != 2:
              print "incorrect arguments, please use the following format:"
              print "rm <id>"
              continue

           command_rm(argv[1])
        else:
           print "Unknown command: " + command


if __name__ == '__main__':
    main()
