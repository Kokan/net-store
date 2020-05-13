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
                    StrFixedLenField("op", "+", length=1),
                    IntField("id", 0),
                    IntField("data", 0xDEADBABE)]

bind_layers(Ether, P4calc, type=ETHER_TYPE)




def main():

    s = ''
    iface = 'eth0'

    while True:
        s = str(raw_input('> '))
        argv = s.split()
        if len(argv) > 0:
           command = argv[0]
        else:
           command = ""

        if command == "quit":
           break

        if command == "put":
           try:
               pkt = Ether(dst='00:04:00:00:00:00', type=ETHER_TYPE) / P4calc(op='+', id=1, data=int(argv[1]))

               srp1(pkt, iface=iface, timeout=1, verbose=False)

           except Exception as error:
               print error

        if command == "get":
           try:
               pkt = Ether(dst='00:04:00:00:00:00', type=ETHER_TYPE) / P4calc(op='-', id=1, data=0)

               resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
               if resp:
                   p4calc=resp[P4calc]
                   if p4calc:
                       print "ID: {} Value: {}".format(p4calc.id, p4calc.data)
                   else:
                       print "cannot find P4calc header in the packet"
               else:
                   print "No reply is recieved"
                 
           except Exception as error:
               print error



if __name__ == '__main__':
    main()
