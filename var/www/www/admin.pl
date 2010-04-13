#! /usr/bin/perl -W
# Main page for the router.  Shows a brief summary of interfaces.
#
use strict;
use warnings;
use CGI;
use CGI::Ajax;
require include::CheckConfig;


use vars qw(
	%querystring %postfield
	@varquery @vardata $maxvar $qline $pline @values $ok $cfgdiff
	$uname
	$aDisplay @aStyle $a $aline
	$pDisplay
);
my %pData;

getEnv();
getInfo();
if ($varquery[0] eq "debug"){
	pageDebug();
}
if ($varquery[0] eq "upgrade"){
	pageUpgrade();
}
if ($varquery[0] eq "reboot"){
	pageReboot();
}
$cfgdiff = CheckConfig::Check();


my $cgi = CGI->new();
my $ajax = CGI::Ajax->new( 'getInfo' => \&getInfo );
print $ajax->build_html ( $cgi, \&main );

sub main {

	my $html = <<EOHTML;
	<html>
	<head>
		<title>DTECH Labs - Router</title>
		<link href='../css/style.css' rel='stylesheet' type='text/css'>
		<script language='javascript'>
		<!-- //
			function setDisable(obj)
			{
				if(obj.checked)
				{
					document.forms[0].pHoldoff.style.backgroundColor = "#ffffff";
					document.forms[0].pHoldoff.readOnly = 0;
				} else {
					document.forms[0].pHoldoff.style.backgroundColor = "#808080";
					document.forms[0].pHoldoff.readOnly = 1;
				}
			}
		// -->
		</script>
	</head>
	<style type="text/css">
		ul.tabs { list-style-type: none;
				  padding: 0;
				  margin: 0px 20px 5px}
		ul.tabs li { float: left;
					 padding: 1;
					 margin: 0;
					 padding-top: 0;
					 margin-right: 1px;
					 width: 100px;
					 background-color: #000000;}
		ul.tabs li a { display:
					   block;
					   padding: 0px 10px;
					   color: white;
					   text-decoration: none;}
		ul.tabs li a:hover { background-color: #BFCFCF; color: black; }
	</style>
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
			<a id='menuLink' href='admin.pl'>ISDN</a>&nbsp;
			<a id='menuLink' href='routing.pl'>routing</a>&nbsp;
			<a id='menuLink' href='security.pl'>security</a>&nbsp;
			<a id='menuLink' href='admin.pl'>admin</a>
		</div>
		$cfgdiff
		<div id='content'>
			<h2>ISDN Peer Configuration</h2>
			<div id='colFull'>
				<fieldset style='height: 400px;'>
				<ul class="tabs">
					<li style="$aStyle[1]"><a href='admin.pl?p=debug' style="$aStyle[1]">debug</a></li>
					<li style="$aStyle[2]"><a href='admin.pl?p=upgrade' style="$aStyle[2]">upgrade</a></li>
					<li style="$aStyle[3]"><a href='admin.pl?p=reboot' style="$aStyle[3]">reboot</a></li>
				</ul><br>
				<img src='../images/spacer.gif' width=1px height=10px>
				$pDisplay
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
	<br><br>
	</body>
	</html>
EOHTML
	return $html;
}

sub getEnv {
	my($i, $x, $name);

	$qline = $ENV{'QUERY_STRING'};
	@values = split(/&/, $qline);
	$x=0;
	if ($values[0] ne ""){
		foreach $i(@values) {
			($name, $varquery[$x]) = split(/=/, $i);
			$x++;
		}
	}

	read(STDIN, $aline, $ENV{'CONTENT_LENGTH'});
	@values = split(/&/, $pline);
	$x=0;
	if ($values[0] ne ""){
		foreach $i(@values) {
			$maxvar = $x;
			($name, $vardata[$x]) = split(/=/, $i);
			$vardata[$x] =~ tr/+/ /;
			$vardata[$x] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			$x++;
		}
	}
}


sub getInfo {
	$uname=`uptime`;
	return 1;
}

sub pageDebug {
}
sub pageUpgrade {
	$pDisplay = "<form ENCTYPE='multipart/form-data' name='peer' action='upgrade.pl' method='POST'>".
				"<table class='upgrade' cellspacing='0' style='float: left'>".
				"<tr><td class='fLabel'>Select upgrade file:</td><td class='fValue'><input class='file' type='file' name='fName' size='50'></td></tr>".
				"<tr><td class='fLabel'>Enter password for file:</td><td class='fValue'><input type='text' name='fPassword' size='50'></td></tr>".
				"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
				"<tr><td colspan=2><center><input class='pButton' type='submit' value='Commit' name='pCmd'>&nbsp;</center></td>".
				"</table>".
				"</form>"
				;

}
sub pageReboot {
}
