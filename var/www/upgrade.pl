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
system "/bin/cp $upload_dir/$filename /tmp/package.tar.bz2";



print "<br><br>Services restarting<br><a href='/info.pl'>main page</a></body></html>";
sleep 5;

system "/sbin/reboot";





