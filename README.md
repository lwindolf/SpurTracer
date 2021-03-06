1. Introduction
===============

SpurTracer is a push-notification based monitoring solution for heterogenous 
loosely coupled IT infrastructures. It complements a service-endpoint 
monitoring solution like Nagios with a component-level interface auto-discovery.

It automatically provides a certain level of functional tracing along with 
many non-functional measurements (e.g. call, error and timeout rates, 
interface latency, component execution...).

While being zero config itself, SpurTracer relies on you adding push 
notification support to the components you want to monitor. The best way 
to use SpurTracer is by adding punctual tracing to components in your 
infrastructure on-demand.


Features

- Zero Configuration: Auto-Discovery of Components and Interfaces
- Out-of-the-box Monitoring of Non-Functional Aspects of Components 
  and Interfaces
- Simple Nagios Integration


2. License
==========

The SpurTracer code is licensed as GPLv3. The code comprises everything
except for the js/ subdirectory in this source distribution.

Please note that the js/ subdirectory contains Javascript libraries which 
do have other licenses listed below:

	JQuery 2.1.1		MIT or GPL Version 2 licensed
	Visualize		MIT or GPL Version 2 licensed
	timeago			MIT or GPL Version 2 licensed
	

Thanks to the respective authors allowing to use these versatile GUI libraries!


3. Installation
===============

3.1 Dependencies
----------------

SpurTracer relies on the following software stack:

1.) Perl 5
2.) Perl modules

    - XML::Writer (soon to be deprecated)
    - Net::Server
    - JSON
    - Error
    - Redis

3.) Redis 1.3 or later


3.2 Installing via OS-Packages
------------------------------

You can install the following distribution specific packages

   Debian (Wheezy and later): 

	apt-get install libxml-writer-perl libnet-server-perl libredis-perl \
			liberror-perl libjson-perl redis-server

If you want Nagios integration you might want to install

   Debian:

	apt-get install nsca

   RHEL:

	yum install nagios-nsca-client


3.3 Installing Perl Modules from CPAN
-------------------------------------

While Perl should be included in your Unix distribution it might 
be that the modules are not available. In this case fetch the
modules via CPAN. Launch the CPAN shell as following:

	perl -MCPAN -e shell

And install the packages by typing the following at the prompt

	> install XML::Writer
	> install Net::Server
        > install JSON
	> install Redis
	> install Error


3.4 Redis Installation
----------------------

If you have installed the Redis package from your distribution you probably
have nothing to do. Please ensure that the Redis instance is up and running
using the CLI client. Type

	redis-cli

You should get a prompt looking like

	redis 127.0.0.1:6379>

This means Redis is running on localhost under default port 6379, which is
what SpurTracer will access per-default.

If you perform a manual setup ensure that Redis is running on its default
port and is bound only to localhost.


3.5 Starting SpurTracer
----------------------

If everything is prepared try starting SpurTrace by running

	./spurtracerd.pl

from the source directory. If no errors are given try to access the server
via your browser or a local HTTP client. The default configuration will
listen on http://localhost:8080. To use a different port run

	./spurtracerd.pl --port=<port>

As Spurtracer uses Net::Server you can use all documented Net::Server
options to change the server behaviour. A full list can be found at:

  http://search.cpan.org/~rhandom/Net-Server-2.008/lib/Net/Server.pod#DEFAULT_ARGUMENTS_FOR_Net::Server

Note that all arguments can you specified as key value pairs as shown with
"port" in the example above.


4. Support
==========

If you have any setup problems or cannot get the code or if you have found 
a functional bug please create a bug in the Github issue tracker:

	https://github.com/lwindolf/SpurTracer/issues
