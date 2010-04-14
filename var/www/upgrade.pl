#!/usr/bin/perl -W

use strict;
use warnings;
use CGI;
my $upload_dir = "/var/www/upload";
my $query = new CGI;


my $filename = $query->param("fName");
my $password = $query->param("fPassword");
$filename =~ s/.*[\/\\](.*)/$1/;
my $upload_filehandle = $query->upload("fName");


print "<html><body>Uploading....   ";
open(UPLOADFILE, ">$upload_dir/$filename") or die "Can't open '$upload_dir/$filename': $!";
binmode UPLOADFILE;
while ( <$upload_filehandle> )
{
print UPLOADFILE;
}
close UPLOADFILE;

print "Done. ";
system "/bin/cp \"$upload_dir/$filename\" /tmp/upgrade.tbz";
system "/bin/tar jxf /tmp/upgrade.tbz usr/bin/dt/scripts/runfirst.sh -C /tmp";
if (-e /usr/bin/dt/scripts/runfirst.sh){
	system "/bin/sh /usr/bin/dt/scripts/runfirst.sh";
}

sleep 5;

print "<br><br>Services restarted<br><a href='/info.pl'>main page</a></body></html>";




