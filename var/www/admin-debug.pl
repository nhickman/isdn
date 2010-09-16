use XML::Twig;
use strict;
#use Unix::PasswdFile;
use CGI;
#Uncomment this line for debug
use CGI::Carp qw/fatalsToBrowser/;

$CGI::POST_MAX = 1024000;
$CGI::DISABLE_UPLOADS = 1;
my $q = CGI->new;

my $debug = 0;

my $fConfigRunning = "/ftp/config-run.xml";
my $fConfigStartup = "/ftp/config.xml";
my $fConfigPeers = "/etc/ppp/peers/isdn/bch*";
my $fConfigBCH1 = "/etc/ppp/peers/isdn/bch1";
my $fConfigBCH2 = "/etc/ppp/peers/isdn/bch2";
my $fConfigBCH3 = "/etc/ppp/peers/isdn/bch3";
my $fConfigBCH4 = "/etc/ppp/peers/isdn/bch4";
my $fConfigBCH5 = "/etc/ppp/peers/isdn/bch5";
my $fConfigBCH6 = "/etc/ppp/peers/isdn/bch6";
my $fConfigBCH7 = "/etc/ppp/peers/isdn/bch7";
my $fConfigBCH8 = "/etc/ppp/peers/isdn/bch8";

my $fLogSystem = "/ftp/debug";
my $fLogRouter = "/ftp/router.log";
my $fLogPeers = "/ftp/ppp-bchan*.log";
my $fLogBCH1 = "/ftp/ppp-bchan1.log";
my $fLogBCH2 = "/ftp/ppp-bchan2.log";
my $fLogBCH3 = "/ftp/ppp-bchan3.log";
my $fLogBCH4 = "/ftp/ppp-bchan4.log";
my $fLogBCH5 = "/ftp/ppp-bchan5.log";
my $fLogBCH6 = "/ftp/ppp-bchan6.log";
my $fLogBCH7 = "/ftp/ppp-bchan7.log";
my $fLogBCH8 = "/ftp/ppp-bchan8.log";

#my $cmdZip = "/usr/bin/7za a $fZip &> /dev/null";
my $fDownloadFile = "";

sub download {
	# Uncomment the next line only for debugging the script 
	#open(my $DLFILE, '<', "$path_to_files/$file") or die "Can't open file '$path_to_files/$file' : $!";
 
	# Comment the next line if you uncomment the above line 
	open(my $DLFILE, '<', "$fDownloadFile") or return(0);
 
	# this prints the download headers with the file size included
	# so you get a progress bar in the dialog box that displays during file downloads. 
	print $q->header(-type            => 'application/x-download',
					-attachment      => $fDownloadFile,
                    -Content_length  => -s "$fDownloadFile",
	);
 
	binmode $DLFILE;
	print while <$DLFILE>;
	undef ($DLFILE);
	return(1);
}
 
##
## Action
##	0 - What are we doing: config-run, config-start, config-all, logs, all
##
my $action = $q->param('a');
#print "Action = " . $action . "\n";
#exit 0;
if ($action eq "") {
	exit 0;
}

# Download requests

if ($action eq "get-config-running"){
	$fDownloadFile = "/ftp/isdnrtr-config-run.7z";
	my $cmd = "/usr/bin/7za a $fDownloadFile $fConfigRunning &> /dev/null";
	system $cmd;
	download();
	system "rm -rf $fDownloadFile";
}

if ($action eq "get-config-startup"){
	$fDownloadFile = "/ftp/isdnrtr-config-start.7z";
	my $cmd = "/usr/bin/7za a $fDownloadFile $fConfigStartup &> /dev/null";
	system $cmd;
	download();
	system "rm -rf $fDownloadFile";
}

if ($action eq "get-config-all"){
	$fDownloadFile = "/ftp/isdnrtr-config-all.7z";
	my $cmd = "/usr/bin/7za a $fDownloadFile $fConfigRunning $fConfigStartup $fConfigPeers &> /dev/null";
	system $cmd;
	download();
	system "rm -rf $fDownloadFile";
}

if ($action eq "get-logs"){
	$fDownloadFile = "/ftp/isdnrtr-logs.7z";
	my $cmd = "/usr/bin/7za a $fDownloadFile $fLogSystem $fLogPeers $fLogRouter &> /dev/null";
	system $cmd;
	download();
	system "rm -rf $fDownloadFile";
}

if ($action eq "get-all"){
	$fDownloadFile = "/ftp/isdnrtr-all.7z";
	my $cmd = "/usr/bin/7za a $fDownloadFile $fConfigRunning $fConfigStartup $fLogSystem  $fConfigPeers $fLogRouter &> /dev/null";
	system $cmd;
	download();
	system "rm -rf $fDownloadFile";
}


## View actions

if ($action eq "view-config-running"){
	my $f = $fConfigRunning;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}

if ($action eq "view-config-startup"){
	my $f = $fConfigStartup;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}

if ($action eq "view-config-bch1"){
	my $f = $fConfigBCH1;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch2"){
	my $f = $fConfigBCH2;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch3"){
	my $f = $fConfigBCH3;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch4"){
	my $f = $fConfigBCH4;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch5"){
	my $f = $fConfigBCH5;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch6"){
	my $f = $fConfigBCH6;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch7"){
	my $f = $fConfigBCH7;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-config-bch8"){
	my $f = $fConfigBCH8;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-system"){
	my $f = $fLogSystem;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-router"){
	my $f = $fLogRouter;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch1"){
	my $f = $fLogBCH1;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch2"){
	my $f = $fLogBCH2;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch3"){
	my $f = $fLogBCH3;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch4"){
	my $f = $fLogBCH4;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch5"){
	my $f = $fLogBCH5;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch6"){
	my $f = $fLogBCH6;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch7"){
	my $f = $fLogBCH7;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}
if ($action eq "view-log-bch8"){
	my $f = $fLogBCH8;
	my $output = `/bin/cat $f`;
	print "Printing $f \n\n";
	print $output;
}

#Load Default Config
if ($action eq "config-default"){
	print "Loading default config...  ";
	system "/bin/cp /ftp/config-default.xml /ftp/config.xml";
	print "Done.\n";
	
	print "The router's IP address will be 192.168.50.1 after reboot.\n\n";
	
	print "Rebooting...\n";
	my $cmd = "/sbin/reboot";
	system $cmd;
}


#Reboot
if ($action eq "reboot"){
	print "Rebooting...\n";
	my $cmd = "/sbin/reboot";
	system $cmd;
	
}

#Hidden actions
if ($action eq "dir-ftp"){
	print "Hidden dir-ftp\n";
	my $output = `/bin/ls -alR /ftp`;
	print $output;
}
if ($action eq "dir-etc"){
	print "Hidden dir-etc\n";
	my $output = `/bin/ls -alR /etc`;
	print $output;
}
if ($action eq "dir-www"){
	print "Hidden dir-www\n";
	my $output = `/bin/ls -alR /var/www`;
	print $output;
}
if ($action eq "dir-dt"){
	print "Hidden dir-dt\n";
	my $output = `/bin/ls -alR /usr/bin/dt`;
	print $output;
}
if ($action eq "dir-root-only"){
	print "Hidden dir-root-only\n";
	my $output = `/bin/ls -al /`;
	print $output;
}
if ($action eq "get-fs"){
	$fDownloadFile = "/ftp/isdnrtr-fs.7z";
	my $cmd = "/usr/bin/7za a $fDownloadFile / &> /dev/null";
	system $cmd;
	download();
	system "rm -rf $fDownloadFile";
}
if ($action eq "ps"){
	print "Running processes\n";
	my $output = `/bin/ps aux`;
	print $output;
}
if ($action eq "7z-check"){
	print "Check 7zip\n";
	my $output = `/usr/bin/7z --help`;
	print $output;
}

exit 0;
