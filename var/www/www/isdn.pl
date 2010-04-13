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
	$pDisplay @pStyle $p
	@pLink
	$pName @pLocalIP @pRemoteIP $pNumber $pPersist $pHoldoff $pMtu $pMru @pChan @pChanSel @pChanUsed
	$spName @spLocalIP @spRemoteIP $spNumber $spPersist $spHoldoff $spMtu $spMru @spChan @spChanSel @spChanUsed
	$pDebugView $pDebugReload
);
my %pData;

getEnv();
getInfo();
if ($vardata[$maxvar] eq "Commit"){
	peerCommit();
}
if ($vardata[$maxvar] eq "Dial"){
	peerConn();
}
if ($vardata[$maxvar] eq "Hangup"){
	peerDisc();
}
getPeer();
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
				  margin: 0px 20px 5px;}
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
			<a id='menuLink' href='isdn.pl'>ISDN</a>&nbsp;
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
					<li style="$pStyle[1]"><a href='isdn.pl?p=1' style="$pStyle[1]">$pLink[1]</a></li>
					<li style="$pStyle[2]"><a href='isdn.pl?p=2' style="$pStyle[2]">$pLink[2]</a></li>
					<li style="$pStyle[3]"><a href='isdn.pl?p=3' style="$pStyle[3]">$pLink[3]</a></li>
					<li style="$pStyle[4]"><a href='isdn.pl?p=4' style="$pStyle[4]">$pLink[4]</a></li>
					<li style="$pStyle[5]"><a href='isdn.pl?p=5' style="$pStyle[5]">$pLink[5]</a></li>
					<li style="$pStyle[6]"><a href='isdn.pl?p=6' style="$pStyle[6]">$pLink[6]</a></li>
					<li style="$pStyle[7]"><a href='isdn.pl?p=7' style="$pStyle[7]">$pLink[7]</a></li>
					<li style="$pStyle[8]"><a href='isdn.pl?p=8' style="$pStyle[8]">$pLink[8]</a></li>
				</ul><br>
				<img src='../images/spacer.gif' width=1px height=10px>
				<form name='peer' action="isdn.pl?p=$vardata[0]" method="POST">
					<input type='hidden' name='peer' value="$p">
					$pDisplay
				</form>
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
	my($i, $a, $name);

	$spChan[1] = 0;
	$spChan[2] = 0;
	$spChan[3] = 0;
	$spChan[4] = 0;
	$spChan[5] = 0;
	$spChan[6] = 0;
	$spChan[7] = 0;
	$spChan[8] = 0;


	$qline = $ENV{'QUERY_STRING'};
	@values = split(/&/, $qline);
	$a=0;
	if ($values[0] ne ""){
		foreach $i(@values) {
			($name, $varquery[$a]) = split(/=/, $i);
			$a++;
		}
	}

	read(STDIN, $pline, $ENV{'CONTENT_LENGTH'});
	@values = split(/&/, $pline);
	$a=0;
	if ($values[0] ne ""){
		foreach $i(@values) {
			$maxvar = $a;
			($name, $vardata[$a]) = split(/=/, $i);
			$vardata[$a] =~ tr/+/ /;
			$vardata[$a] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			if ($name eq "peer"){
				$p = $vardata[$a];
			}
			if ($name eq "pName"){
				$spName = $vardata[$a];
			}
			if ($name eq "pNumber"){
				$spNumber = $vardata[$a];
			}
			if ($name eq "pLocalIP1" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spLocalIP[1] = $vardata[$a];
			}
			if ($name eq "pLocalIP2" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spLocalIP[2] = $vardata[$a];
			}
			if ($name eq "pLocalIP3" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spLocalIP[3] = $vardata[$a];
			}
			if ($name eq "pLocalIP4" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spLocalIP[4] = $vardata[$a];
			}
			if ($name eq "pRemoteIP1" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spRemoteIP[1] = $vardata[$a];
			}
			if ($name eq "pRemoteIP2" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spRemoteIP[2] = $vardata[$a];
			}
			if ($name eq "pRemoteIP3" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spRemoteIP[3] = $vardata[$a];
			}
			if ($name eq "pRemoteIP4" && $vardata[$a] >= 0 && $vardata[$a] <=255){
				$spRemoteIP[4] = $vardata[$a];
			}
			if ($name eq "pPersist"){
				$spPersist = $vardata[$a];
			}
			if ($name eq "pHoldoff"){
				$spHoldoff = $vardata[$a];
			}
			if ($name eq "pMtu" && $vardata[$a] >= 128 && $vardata[$a] <=16384){
				$spMtu = $vardata[$a];
			}
			if ($name eq "pMru" && $vardata[$a] >= 128 && $vardata[$a] <=16384){
				$spMru = $vardata[$a];
			}
			if ($name eq "pChan1"){
				$spChan[1] = $vardata[$a];
			}
			if ($name eq "pChan2"){
				$spChan[2] = $vardata[$a];
			}
			if ($name eq "pChan3"){
				$spChan[3] = $vardata[$a];
			}
			if ($name eq "pChan4"){
				$spChan[4] = $vardata[$a];
			}
			if ($name eq "pChan5"){
				$spChan[5] = $vardata[$a];
			}
			if ($name eq "pChan6"){
				$spChan[6] = $vardata[$a];
			}
			if ($name eq "pChan7"){
				$spChan[7] = $vardata[$a];
			}
			if ($name eq "pChan8"){
				$spChan[8] = $vardata[$a];
			}
			$a++;
		}
	}
}


sub getInfo {
	$uname=`uptime`;
	return 1;
}

sub getPeer {
	my (@a1, @a2, $x, $y, $pHoldoffEn);
	if ($varquery[0] > 0){
		$p = $varquery[0];
	}
	else {
		if ($vardata[0] > 0) {
			$p = $vardata[0];
		}
	}

	for($x=1;$x<9;$x++){
		#Peer Names
		$pLink[$x] = "Peer ". $x;
		@a1 = `/usr/bin/dt/msgsend 4618 $x`;
		$a1[0] =~ s/\s+$//;
		if ($a1[0] ne ""){
			$pLink[$x] = $a1[0];

		}
	}

	$pDisplay="<div>Select peer to configure</div>";
	if ($p > 0 && $p < 9){
		#set default values
		$pLocalIP[1] = 0;
		$pLocalIP[2] = 0;
		$pLocalIP[3] = 0;
		$pLocalIP[4] = 0;
		$pRemoteIP[1] = 0;
		$pRemoteIP[2] = 0;
		$pRemoteIP[3] = 0;
		$pRemoteIP[4] = 0;
		$pNumber = "";
		$pMtu = 30;
		$pMtu = 1500;
		$pMru = 1500;
		$pChan[1] = 0;
		$pChan[2] = 0;
		$pChan[3] = 0;
		$pChan[4] = 0;
		$pChan[5] = 0;
		$pChan[6] = 0;
		$pChan[7] = 0;
		$pChan[8] = 0;

		#get values from MC

		#Peer Names
		$pName = $pLink[$p];

		#Dial Number
		@a1 = `/usr/bin/dt/msgsend 4610 $p`;
		$pNumber = $a1[0];

		#Local IP
		@a1 = `/usr/bin/dt/msgsend 4611 $p`;
		$pLocalIP[0] = $a1[0];
		@a2 = split(/\./, $pLocalIP[0]);
		$pLocalIP[1] = $a2[0];
		$pLocalIP[2] = $a2[1];
		$pLocalIP[3] = $a2[2];
		$pLocalIP[4] = $a2[3];

		#Remote IP
		@a1 = `/usr/bin/dt/msgsend 4612 $p`;
		$pRemoteIP[0] = $a1[0];
		@a2 = split(/\./, $pRemoteIP[0]);
		$pRemoteIP[1] = $a2[0];
		$pRemoteIP[2] = $a2[1];
		$pRemoteIP[3] = $a2[2];
		$pRemoteIP[4] = $a2[3];

		@a1 = `/usr/bin/dt/msgsend 4613 $p`;
		$pHoldoffEn="style='background-color: #808080; width: 100px;'";
		if ($a1[0] == 1){
			$pPersist="checked";
			$pHoldoffEn="style='background-color: #ffffff; width: 100px;'";
		}
		@a1 = `/usr/bin/dt/msgsend 4614 $p`;
		$pHoldoff = $a1[0];
		@a1 = `/usr/bin/dt/msgsend 4615 $p`;
		$pMru = $a1[0];
		@a1 = `/usr/bin/dt/msgsend 4616 $p`;
		$pMtu = $a1[0];

		#Used Channels
		#first get all channels that are used so we can disable boxes that arent available
		for ($x=1;$x<9;$x++){
			if ($x != $p){
				@a1 = `/usr/bin/dt/msgsend 4617 $x`;
				$pChanUsed[0] = $a1[0];
				@a2 = split(/ /, $a1[0]);
				for ($y=0;$y<8;$y++){
					$a2[$y] =~ s/\s+$//;
					if ($a2[$y] == 1){
						$pChanUsed[$y+1]="disabled";
					}
				}
			}
		}
		@a1 = `/usr/bin/dt/msgsend 4617 $p`;
		$pChan[0] = $a1[0];
		@a2 = split(/ /, $pChan[0]);
		for ($x=1;$x<9;$x++){
			$pChan[$x] = $a2[$x-1];
			if ($pChan[$x] == 1 && $pChanUsed[$x] eq ""){
				$pChanSel[$x]="checked";
			}
		}

		#change menu display for selected peer
		$pStyle[$p]="background-color: #BFCFCF; color: #000000;";

		#form display with defaults or with values if returned.
		$pDisplay="<div style='margin: 0px 0px 20px 0px;'>Peer configuration #" . $p . "<br></div>".
					"<table class='peer' cellspacing='0' style='float: left'>".
					"<tr><td class='pLabel'>Peer Name:&nbsp;</td><td colspan=2 class='pValue'><input name='pName' type='text' value='".$pName."' maxlength=12 style='width: 100px;' /> <i>(12 chars max)</i></td></tr>".
					"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
					"<tr><td class='pLabel'>Dial Number:&nbsp;</td><td colspan=2 class='pValue'><input name='pNumber' type='text' value='".$pNumber."' maxlength=50 style='width: 100px;' /> <i>(acceptable digits: 0-9, #, *)</i></td></tr>".
					"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
					"<tr><td class='pLabel'>Local IP:&nbsp;</td><td class='pValue'><input name='pLocalIP1' type='text' value='$pLocalIP[1]' maxlength=3 style='width: 30px;' />.<input name='pLocalIP2' type='text' value='$pLocalIP[2]' maxlength=3 style='width: 30px'/>.<input name='pLocalIP3' type='text' value='$pLocalIP[3]' maxlength=3 style='width: 30px'/>.<input name='pLocalIP4' type='text' value='$pLocalIP[4]' maxlength=3 style='width: 30px'/></td></tr>".
					"<tr><td class='pLabel'>Remote IP:&nbsp;</td><td class='pValue'><input name='pRemoteIP1' type='text' value='$pRemoteIP[1]' maxlength=3 style='width: 30px;' />.<input name='pRemoteIP2' type='text' value='$pRemoteIP[2]' maxlength=3 style='width: 30px'/>.<input name='pRemoteIP3' type='text' value='$pRemoteIP[3]' maxlength=3 style='width: 30px'/>.<input name='pRemoteIP4' type='text' value='$pRemoteIP[4]' maxlength=3 style='width: 30px'/></td></tr>".
					"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
					"<tr><td class='pLabel'>Persistant:&nbsp;</td><td colspan=2><input $pPersist class='pCheck' type='checkbox' value='1' name='pPersist' id='pPersist' onClick='setDisable(this)' /> <i>(keeps dialer alive for retry after holdoff expiration)</i></td></tr>".
					"<tr><td class='pLabel'>Holdoff:&nbsp;</td><td colspan=2 class='pValue'><input id='pHoldoff' name='pHoldoff' type='text' value='".$pHoldoff."' $pHoldoffEn maxlength=20' /> <i>(holdoff time to redial)</i></td></tr>".
					"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
					"<tr><td class='pLabel'>MTU:&nbsp;</td><td colspan=2 class='pValue'><input name='pMtu' type='text' value='".$pMtu."' maxlength=5 style='width: 50px;' /> <i>(default:1500 min:128 max:16384)</i></td></tr>".
					"<tr><td class='pLabel'>MRU:&nbsp;</td><td colspan=2 class='pValue'><input name='pMru' type='text' value='".$pMru."' maxlength=5 style='width: 50px;' /> <i>(default:1500 min:128 max:16384)</i></td></tr>".
					"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
					"<tr><td class='pLabel'>B Channels:&nbsp;</td><td colspan=2><input $pChanUsed[1] $pChanSel[1] class='pCheck' type='checkbox' value='1' name='pChan1' id='pChan1'/><label class='pLabel'>Port1 B1</label><input $pChanUsed[3] $pChanSel[3] class='pCheck' type='checkbox' value='1' name='pChan3'><label class='pLabel'>Port2 B1</label><input $pChanUsed[5] $pChanSel[5] class='pCheck' type='checkbox' value='1' name='pChan5'><label class='pLabel'>Port3 B1</label><input $pChanUsed[7] $pChanSel[7] class='pCheck' type='checkbox' value='1' name='pChan7'><label class='pLabel'>Port4 B1</label></td></tr>".
					"<tr><td class='pLabel'>&nbsp;</td><td colspan=2><input $pChanUsed[2] $pChanSel[2] class='pCheck' type='checkbox' value='1' name='pChan2'><label class='pLabel'>Port1 B2</label><input $pChanUsed[4] $pChanSel[4] class='pCheck' type='checkbox' value='1' name='pChan4'><label class='pLabel'>Port2 B2</label><input $pChanUsed[6] $pChanSel[6] class='pCheck' type='checkbox' value='1' name='pChan6'><label class='pLabel'>Port3 B2</label><input $pChanUsed[8] $pChanSel[8] class='pCheck' type='checkbox' value='1' name='pChan8'><label class='pLabel'>Port4 B2</label></td></tr>".
					"<tr><td colspan=2 style='height: 5px;'>&nbsp;</td></tr>".
					"<tr><td>&nbsp;</td><td colspan=3><input class='pButton' type='submit' value='Commit' name='pCmd'>&nbsp;<input class='pButton' type='submit' value='Dial' name='pCmd'>&nbsp;<input class='pButton' type='submit' value='Hangup' name='pCmd'></td>".
					"</table>"
					;

	}
}

sub peerCommit {
	my (@a1);
#$pName @pLocalIP @pRemoteIP $pNumber $pPersist $pHoldoff $pMtu $pMru @pChan @pChanSel @pChanUsed
#M_CMD_PEER_USER	0x0200	/* 512 */
#M_CMD_PEER_PW		0x0201	/* 513 */
#M_CMD_PEER_NUM		0x0202	/* 514 */
#M_CMD_PEER_LOCIP	0x0203	/* 515 */
#M_CMD_PEER_REMIP	0x0204	/* 516 */
#M_CMD_PEER_PERSIST	0x0205	/* 517 */
#M_CMD_PEER_HOLDOFF	0x0206	/* 518 */
#M_CMD_PEER_MRU		0x0207	/* 519 */
#M_CMD_PEER_MTU		0x0208	/* 520 */
#M_CMD_PEER_CHAN	0x0209	/* 521 */

	@a1 = `/usr/bin/dt/msgsend 522 $p $spName`;
#	@a1 = `/usr/bin/dt/msgsend 512 $p`;
#	@a1 = `/usr/bin/dt/msgsend 513 $p`;
	@a1 = `/usr/bin/dt/msgsend 514 $p $spNumber`;
	if ($spLocalIP[1] >= 0 && $spLocalIP[1] <= 255 &&
		$spLocalIP[2] >= 0 && $spLocalIP[2] <= 255 &&
		$spLocalIP[3] >= 0 && $spLocalIP[3] <= 255 &&
		$spLocalIP[4] >= 0 && $spLocalIP[4] <= 255) {
		@a1 = `/usr/bin/dt/msgsend 515 $p $spLocalIP[1].$spLocalIP[2].$spLocalIP[3].$spLocalIP[4]`;
	}
	if ($spRemoteIP[1] >= 0 && $spRemoteIP[1] <= 255 &&
		$spRemoteIP[2] >= 0 && $spRemoteIP[2] <= 255 &&
		$spRemoteIP[3] >= 0 && $spRemoteIP[3] <= 255 &&
		$spRemoteIP[4] >= 0 && $spRemoteIP[4] <= 255) {
		@a1 = `/usr/bin/dt/msgsend 516 $p $spRemoteIP[1].$spRemoteIP[2].$spRemoteIP[3].$spRemoteIP[4]`;
	}
	@a1 = `/usr/bin/dt/msgsend 517 $p $spPersist`;
	@a1 = `/usr/bin/dt/msgsend 518 $p $spHoldoff`;
	if ($spMru >0){
		@a1 = `/usr/bin/dt/msgsend 519 $p $spMru`;
	}
	if ($spMru >0){
		@a1 = `/usr/bin/dt/msgsend 520 $p $spMtu`;
	}
	@a1 = `/usr/bin/dt/msgsend 521 $p $spChan[1] $spChan[2] $spChan[3] $spChan[4] $spChan[5] $spChan[6] $spChan[7] $spChan[8]`;
	@a1 = `/usr/bin/dt/msgsend 523 $p`;

}

sub peerConn {
	my @a1 = `/usr/bin/dt/msgsend 772 $p`;
}

sub peerDisc {
	my @a1 = `/usr/bin/dt/msgsend 773 $p`;
}
