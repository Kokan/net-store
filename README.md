Programmable networks class assignment
====

In-network data store: store information in the network with circulating packages keeping the data.

Topology
===

In order to store data in the network there must be a circule of network devices forwarding the messages indefinitly. While it is possible to come up different topologies, and the solution itself should be topology agnostic in a sense that it is given, and the algorithm should not depend on much of its structure.

A few possible way to achieve this would be:
1. When a data is initialized and sent toward the network, the chain of devices must be specified. Those devices should forward the message in that order. The smallest such set could be one device that must always forward the data to itself.
2. The possible routes are stored in each device table, which only knows a rule how to forward to the next hop the current message. 

While both option has their own challange I would use the 2nd option as the 1st option also requires a package to store a path therefore it could hold less data.


Supported operation
===

The usualy operation should be supported: put, get and remove data from the storage. A simple python interface should provides those methods. The data must have a uniq identifier in order to fetch or remove from the network. (This could be a hash or counter.)

Optional: list operation could be also implemented.  But the list operation would require a structure that could bookeep about the possible entries (see inode). An alternative could be a watch operation, that sends every ID toward the watcher, which than could query the data of its own choosing.


How would it work?
====

Sending data toward the network is easy, as it should just send toward any device in the circle of life. From that point toward the each device should forward the message to the proper next hop (see above about the how forwarding could be achived).
Additionally when the packate first published via put, a reply must be sent back to the sender with the uniq ID anybody could reference the packet.

The get operation must have a valid ID, that it sends towards the device (validity of the ID won't be checked as part of this project) that is stored in the device as in a processing queue (could be implemented as register) a processing queue would store the source of request and the ID, when a packet with a proper ID is recieved; when that happens it must forward the data as usually and clone the message, send to the get request sender as well and remove the request from the process queue.

The remove should work identical to the get, but the device should not forward the message just send an ack. about the successfull removing operation.

Note: it is possible that the request queue is got full, which could be resolved with multiple option:
1. reject new request untill there is space
2. replaces the oldest request with the current (send failure due to timeout to the sender)
3. set a timeout with the number of packet seen, or elapsed seconds
4. circulate a process queue empty message which acts like the 2nd option but process queue amount of new empty request


