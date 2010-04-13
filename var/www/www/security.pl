#! /usr/bin/perl -W
# Main page for the router.  Shows a brief summary of interfaces.
#
use strict;
use warnings;
use CGI;
use CGI::Ajax;
require include::CheckConfig;


use vars qw(
	$uname $cfgdiff
);
$cfgdiff = CheckConfig::Check();
getInfo();


my $cgi = CGI->new();
my $ajax = CGI::Ajax->new( 'getInfo' => \&getInfo );
print $ajax->build_html ( $cgi, \&main );

sub main {

	my $html = <<EOHTML;
	<html>
	<head>
		<title>DTECH Labs - Router</title>
		<link href='../css/style.css' rel='stylesheet' type='text/css'>
	</head>
	<body>
	<center>
	<div id='wrapper'>
		<div id='header'>
			<div id='logo'>
				<img src='../images/banner100.jpg'>
			</div>
		</div>
		<div id='menuDiv'>
			<a id='menuLink' href='/'>status</a>&nbsp;
			<a id='menuLink' href='ethernet.pl'>ethernet</a>&nbsp;
			<a id='menuLink' href='isdn.pl'>ISDN</a>&nbsp;
			<a id='menuLink' href='routing.pl'>routing</a>&nbsp;
			<a id='menuLink' href='security.pl'>security</a>&nbsp;
			<a id='menuLink' href='admin.pl'>admin</a>
		</div>
		$cfgdiff
		<div id='content'>
			<h2>System Security</h2>
			<div id='colFull'>
				<fieldset style='height: 400px;'>
				</fieldset>
			</div>
		</div>
		<br clear='all'>
		<div id='footer'>
			<div id='system' class='system'>
				$uname
			</div>
		</div>
	</div>
	</center>
	</body>
	</html>
EOHTML
	return $html;
}

sub getInfo {
	$uname=`uptime`;
	return 1;
}
