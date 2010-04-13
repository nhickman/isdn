#!/usr/bin/perl
use IO::File;

my $file_name = "../../../../etc/rc.d/rc.inet1.conf";
open(FH, "< $file_name");
while (<FH>) {
    chomp;                  # no newline
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
    $prefs{$var} = $value;
    #print $var . " = " . $value . "\n";
} ;

print $prefs{"IPADDR[0]"};