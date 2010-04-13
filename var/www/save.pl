#!/usr/bin/perl
# Perl script redirect to another http/ftp url or a page
# You can call perl script as follows:
#
# A) Redirect to url cyberciti.biz
# http://mydomain.com/cgi-bin/rd?url=http://cyberciti.biz/
#
# B) To call perl script from html page as javascript
# (put in your html file, note o=js option at the END):
#!/usr/bin/perl -w

use strict;
use warnings;
use CGI;

# new CGI
my $q = CGI->new( );
my $error;
# get url param
my $rdurl = $ENV{HTTP_REFERER};
my $output = lc($q->param("o"));
my $ret;
# make sure url passed as url=http://somewhere.com/page.html
if ( $rdurl eq "" ){
  print $q->header();
  print $q->start_html(-title=>"Error URL missing");
  print $error;
  print $q->end_html();
}
else{ # redirect to a page
    if ( $output eq "" || $output eq "html" ){
	    exec `perl /usr/bin/dt/scripts/config-read.pl save`;
    	print $q->redirect( -URL => $rdurl);
    }
    else {
      # do javascript based redirection / a page
      # Send fresh header or sky will fall on you :P
      print $q->header();
      # do a page redirection with javascript
      print "window.location=\"$rdurl\";\n\n";
    }
}
exit 0;