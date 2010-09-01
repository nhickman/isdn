use XML::Twig;
use strict;

# Run routines to reboot the system.
# --- Need to add logging output.


# Gracefully close dialers
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 1";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 2";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 3";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 4";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 5";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 6";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 7";
system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl hang run peer 8";

# Reboot the system.
system "/sbin/shutdown -r now";

