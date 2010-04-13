#!/usr/local/bin/perl -W 

print "Content-type: text/html\n\n"; 
print "<html><body>";
       foreach (sort keys %ENV) {
               print "$_  =  $ENV{$_}\n";
                }
print "</body></html>";

 


