Installation
============

Dependencies
------------

SpurTracer relies on the following software stack:

1.) Perl 5
2.) Perl modules

    - XML::Writer
    - Net::Server
    - Redis

3.) Redis


Installing via OS-Packages
--------------------------

You can install the following distribution specific packages

   Debian Wheezy: 

	apt-get install libxml-writer-perl libnet-server-perl libredis-perl redis-server


Installing Perl Modules from CPAN
---------------------------------

While Perl should be included in your Unix distribution it might 
be that the modules are not available. In this case fetch the
modules via CPAN. Launch the CPAN shell as following:

	perl -MCPAN -e shell

And install the packages by typing the following at the prompt

	> install XML::Writer
	> install Net::Server
	> install Redis


Redis Installation
------------------

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


Starting SpurTracer
-------------------

If everything is prepared try starting SpurTrace by running

	./spurtracerd.pl

from the source directory. If no errors are given try to access the server
via your browser or a local HTTP client. The default configuration will
listen on http://localhost:8080


Support
=======

If you have any setup problems or cannot get the code to run please use
the project forum at the SourceForge project page.

	http://sourceforge.net/p/spurtracer/discussion/	


If you have found a functional bug please create a bug in the SourceForge
tracker:

	http://sourceforge.net/p/spurtracer/tickets/
