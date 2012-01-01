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

   Debian: 

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


