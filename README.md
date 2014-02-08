enerjeannie
===========

A tool to control an energenie pms.

This tool automatically logs in and switch state of a socket on or off.

It is possible to define human readable names of devices which is mapped to a socket.


Installation
============

To install this tool you only need to copy jeannie.pl into some bin directory, e.g. /usr/local/bin or ~/bin, and fix settings in first block.

variables to fix:

* $host
** should be set to the hostname/IP of your energenie PMS
* $password
** should be set to the password set in your energenie PMS
* %socketMap
** hash map of human readable socket or device names


Usage
=====

You can use the command with numbers or with words.
Options --socket and --state are required.
/usr/bin/perl jeannie.pl --socket=0|1|2|3|4 --state=0|1

Option "--socket" can be replaced by this alternatives:
* --number
* --nummer
* --sockel

Instead of giving an socket number you can define aliases for each socket in hash %socketMap.
If you try to address a socket by an alias you have to use the options
* --device
* --geraet

The wished state can set by option
* --state or
* --status



Special use cases
-----------------

Socket with ID 0 is a special for each socket have to be switched to target state.

If no socket or device name is given special socket number 0 will be assumed. This means:
Calling <code>/usr/bin/perl jeannie.pl --state=0</code> will *switch off all* sockets.

If no state is given to switch off given socket will be assumed. This means:
Calling <code>/usr/bin/perl jeannie.pl --socket=1</code> will *switch off* socket with ID 1.

Combinations are possible. This means that calling <code>/usr/bin/perl jeannie.pl</code> will switch off all sockets.
