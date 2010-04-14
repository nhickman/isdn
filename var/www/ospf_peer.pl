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
	$pName $pNetwork $pAuth $pAuthKey $pAuthMD $pAuthNull $pMessKeyID $pMessKeyPass $pCost $pMTU $pTimerDefaults $pIntDead $pIntHello $pIntRetrans $pIntTrans $pPriority
	$spName $spNetwork $spAuth $spAuthType $spAuthKey $spAuthMD $spAuthNull $spMessKeyID $spMessKeyPass $spCost $spMTU $spTimerDefaults $spIntDead $spIntHello $spIntRetrans $spIntTrans $spPriority
	$spCmd
	$pDebugView $pDebugReload
);
my %pData;

getEnv();
getInfo();
if ($vardata[$maxvar] eq "Commit"){
	peerCommit();
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
			function setNetworkTimers(obj) {
				if(obj.checked) {
				  if(document.getElementById('pIntDead').value == 40){
						document.getElementById('pIntDead').readonly = 0;;
						document.getElementById('pIntDead').value = 120;
						if(document.getElementById('pDefaultTimers').checked)
							document.getElementById('pIntDead').readonly = 1;
					}
						
				  if(document.getElementById('pIntHello').value == 10){
						document.getElementById('pIntHello').readonly = 0;
						document.getElementById('pIntHello').value = 30;
						if(document.getElementById('pDefaultTimers').checked)
							document.getElementById('pIntHello').readonly = 1;
					}
				} else {
				  if(document.getElementById('pIntDead').value == 120){
						document.getElementById('pIntDead').readonly = 0;
						document.getElementById('pIntDead').value = 40;
						if(document.getElementById('pDefaultTimers').checked)
							document.getElementById('pIntDead').readonly = 1;
					}

				  if(document.getElementById('pIntHello').value == 30){
						document.getElementById('pIntHello').readonly = 0;
						document.getElementById('pIntHello').value = 10;
						if(document.getElementById('pDefaultTimers').checked)
							document.getElementById('pIntHello').readonly = 1;
					}
				}
			}

			function setAuthEnable(obj)	{
				if(obj.checked){
				  document.ospf_peer.pAuthType[0].disabled = false;
				  document.ospf_peer.pAuthType[1].disabled = false;
				  document.ospf_peer.pAuthType[2].disabled = false;
   				document.ospf_peer.pAuthType[0].style.backgroundColor = "#ffffff";
   				document.ospf_peer.pAuthType[1].style.backgroundColor = "#ffffff";
   				document.ospf_peer.pAuthType[2].style.backgroundColor = "#ffffff";

				  if (document.ospf_peer.pAuthType[0].checked){
				    document.getElementById('pAuthKeyID').readOnly = false;
   					document.getElementById('pAuthKeyID').style.backgroundColor = "#ffffff";
				    document.getElementById('pAuthKeyPass').readOnly = false;
   					document.getElementById('pAuthKeyPass').style.backgroundColor = "#ffffff";
				    document.getElementById('pMessKey').readOnly = true;
   					document.getElementById('pMessKey').style.backgroundColor = "#808080";
   				}
				  if (document.ospf_peer.pAuthType[1].checked == true){
				    document.getElementById('pMessKeyID').readonly = 1;
   					document.getElementById('pMessKeyID').style.backgroundColor = "#808080";
				    document.getElementById('pMessKeyPass').readonly = 1;
   					document.getElementById('pMessKeyPass').style.backgroundColor = "#808080";
				    document.getElementById('pAuthKey').readonly = 1;
   					document.getElementById('pAuthKey').style.backgroundColor = "#808080";
   				}
				  if (document.ospf_peer.pAuthType[2].checked == true){
				    document.getElementById('pAuthKey').readonly = 1;
   					document.getElementById('pAuthKey').style.backgroundColor = "#808080";
				    document.getElementById('pMessKeyID').readonly = 0;
   					document.getElementById('pMessKeyID').style.backgroundColor = "#ffffff";
				    document.getElementById('pMessKeyPass').readonly = 0;
   					document.getElementById('pMessKeyPass').style.backgroundColor = "#ffffff";
   				}

				}
				else {
				  document.ospf_peer.pAuthType[0].disabled = true;
				  document.ospf_peer.pAuthType[1].disabled = true;
				  document.ospf_peer.pAuthType[2].disabled = true;
   				document.ospf_peer.pAuthType[0].style.backgroundColor = "#808080";
   				document.ospf_peer.pAuthType[1].style.backgroundColor = "#808080";
   				document.ospf_peer.pAuthType[2].style.backgroundColor = "#808080";
			    document.getElementById('pMessKeyID').readonly = 1;
 					document.getElementById('pMessKeyID').style.backgroundColor = "#808080";
			    document.getElementById('pMessKeyPass').readonly = 1;
 					document.getElementById('pMessKeyPass').style.backgroundColor = "#808080";
			    document.getElementById('pAuthKey').readonly = 1;
 					document.getElementById('pAuthKey').style.backgroundColor = "#808080";

				}
			}
			
			function setAuthType(obj) {
			  if (obj.value == 1){
				    document.getElementById('pAuthKey').readOnly = false;
   					document.getElementById('pAuthKey').style.backgroundColor = "#ffffff";
				    document.getElementById('pMessKeyID').readOnly = true;
   					document.getElementById('pMessKeyID').style.backgroundColor = "#808080";
				    document.getElementById('pMessKeyPass').readOnly = true;
   					document.getElementById('pMessKeyPass').style.backgroundColor = "#808080";
				}
			  if (obj.value == 2){
				    document.getElementById('pMessKeyID').readOnly = true;
   					document.getElementById('pMessKeyID').style.backgroundColor = "#808080";
				    document.getElementById('pMessKeyPass').readOnly = true;
   					document.getElementById('pMessKeyPass').style.backgroundColor = "#808080";
				    document.getElementById('pAuthKey').readOnly = true;
   					document.getElementById('pAuthKey').style.backgroundColor = "#808080";
				}

			  if (obj.value == 3){
				    document.getElementById('pAuthKey').readOnly = true;
   					document.getElementById('pAuthKey').style.backgroundColor = "#808080";
				    document.getElementById('pMessKeyID').readOnly = false;
   					document.getElementById('pMessKeyID').style.backgroundColor = "#ffffff";
				    document.getElementById('pMessKeyPass').readOnly = false;
   					document.getElementById('pMessKeyPass').style.backgroundColor = "#ffffff";
				}
			}
			
			function setTimersEnable(obj){
			  if(obj.checked){
			    document.getElementById('pIntDead').readonly = 0;
 					document.getElementById('pIntDead').style.backgroundColor = "#ffffff";
			    document.getElementById('pIntHello').readonly = 0;
 					document.getElementById('pIntHello').style.backgroundColor = "#ffffff";
			    document.getElementById('pIntRetrans').readonly = 0;
 					document.getElementById('pIntRetrans').style.backgroundColor = "#ffffff";
			    document.getElementById('pIntTrans').readonly = 0;
 					document.getElementById('pIntTrans').style.backgroundColor = "#ffffff";
			  }
			  else {
			    document.getElementById('pIntDead').readonly = 1;
 					document.getElementById('pIntDead').style.backgroundColor = "#808080";
			    document.getElementById('pIntHello').readonly = 1;
 					document.getElementById('pIntHello').style.backgroundColor = "#808080";
			    document.getElementById('pIntRetrans').readonly = 1;
 					document.getElementById('pIntRetrans').style.backgroundColor = "#808080";
			    document.getElementById('pIntTrans').readonly = 1;
 					document.getElementById('pIntTrans').style.backgroundColor = "#808080";
			  }
			}
			function filterNums(evt) {
				var keyCode = evt.which ? evt.which : evt.keyCode;
				return (keyCode >= '0'.charCodeAt() && keyCode <= '9'.charCodeAt()) ||
				keyCode == 8;
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
			<h2>OSPF Peer Configuration</h2>
			<div id='colFull'>
				<fieldset style='height: 460px;'>
				<ul class="tabs">
					<li style="$pStyle[1]"><a href='ospf_peer.pl?p=1' style="$pStyle[1]">OSPF<br>$pLink[1]</a></li>
					<li style="$pStyle[2]"><a href='ospf_peer.pl?p=2' style="$pStyle[2]">OSPF<br>$pLink[2]</a></li>
					<li style="$pStyle[3]"><a href='ospf_peer.pl?p=3' style="$pStyle[3]">OSPF<br>$pLink[3]</a></li>
					<li style="$pStyle[4]"><a href='ospf_peer.pl?p=4' style="$pStyle[4]">OSPF<br>$pLink[4]</a></li>
					<li style="$pStyle[5]"><a href='ospf_peer.pl?p=5' style="$pStyle[5]">OSPF<br>$pLink[5]</a></li>
					<li style="$pStyle[6]"><a href='ospf_peer.pl?p=6' style="$pStyle[6]">OSPF<br>$pLink[6]</a></li>
					<li style="$pStyle[7]"><a href='ospf_peer.pl?p=7' style="$pStyle[7]">OSPF<br>$pLink[7]</a></li>
					<li style="$pStyle[8]"><a href='ospf_peer.pl?p=8' style="$pStyle[8]">OSPF<br>$pLink[8]</a></li>
				</ul><br>
				<img src='../images/spacer.gif' width=1px height=10px>
				<form name='ospf_peer' action="ospf_peer.pl?p=$vardata[0]" method="POST">
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

	$qline = $ENV{'QUERY_STRING'};
	@values = split(/&/, $qline);
	$a=0;
	if ($values[0] ne ""){
		foreach $i(@values) {
			($name, $varquery[$a]) = split(/=/, $i);
			$a++;
		}
		if ($varquery[0] eq "")
		{
		  $p = 0;
		}
	}

	read(STDIN, $pline, $ENV{'CONTENT_LENGTH'});
	@values = split(/&/, $pline);
	
	#set defaults
	$spNetwork=0;
	$spAuth=0;
	$spAuthMD=0;
	$spAuthNull=0;
	$spAuthKey="";
	$spMessKeyID=0;
	$spMessKeyPass="";
	$spCost=0;
	$spMTU=0;
	$spTimerDefaults=0;
	$spIntDead=0;
	$spIntHello=0;
	$spIntRetrans=0;
	$spIntTrans=0;
	
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
			if ($name eq "pNetwork"){
				$spNetwork = $vardata[$a];
			}
			if ($name eq "pAuth"){
				$spAuth = $vardata[$a];
			}
			if ($name eq "pAuthType"){
				$spAuthType = $vardata[$a];
			}
			if ($name eq "pAuthKey"){
				$spAuthKey = $vardata[$a];
			}
			if ($name eq "pMessKeyID"){
				$spMessKeyID = $vardata[$a];
			}
			if ($name eq "pMessKeyPass"){
				$spMessKeyPass = $vardata[$a];
			}
			if ($name eq "pCost" && $vardata[$a] >= 0 && $vardata[$a] <=65535){
				$spCost = $vardata[$a];
			}
			if ($name eq "pMTU"){
				$spMTU = $vardata[$a];
			}
			if ($name eq "pTimerDefaults"){
				$spTimerDefaults = $vardata[$a];
			}
			if ($name eq "pIntDead"){
				$spIntDead = $vardata[$a];
			}
			if ($name eq "pIntHello"){
				$spIntHello = $vardata[$a];
			}
			if ($name eq "pIntRetrans"){
				$spIntRetrans = $vardata[$a];
			}
			if ($name eq "pIntTrans"){
				$spIntTrans = $vardata[$a];
			}
			if ($name eq "pCmd"){
			  $spCmd = $vardata[$a];
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
	my (@a1, @a2, @p_byline, @p_byval, $x, $y, $pLink);
	my ($pNetworkCheck, $pAuthCheck, $pAuthKeyCheck, $pAuthMDCheck, $pAuthNullCheck, $pMTUCheck, $pDefaultTimersCheck);
	my ($pAuthKeyEn, $pAuthTypeEn, $pAuthMDEn, $pIntDeadEn, $pIntHelloEn, $pIntRetransEn, $pIntTransEn);
	my ($pAuthTypeStyle, $pAuthKeyStyle, $pAuthMDStyle, $pIntDeadStyle, $pIntHelloStyle, $pIntRetransStyle, $pIntTransStyle);
	if ($varquery[0] > 0){
		$p = $varquery[0];
	}
	else {
	  $p = 1;
		if ($vardata[0] > 0) {
			$p = $vardata[0];
		}
	}

 	#get peer names
	for($x=1;$x<9;$x++){
		#Peer Names
		$pLink[$x] = "Peer $x";
	}
	
	@p_byline = `perl /usr/bin/dt/scripts/config-read.pl query run peers`;
	foreach my $line (@p_byline){
		chomp($line);
		@p_byval = split(/,/, $line);
		if ($p_byval[1] ne "") { $pLink[$p_byval[0]] = $p_byval[1]; }
	}
	$#p_byline = -1;
	$#p_byval = -1;

	#get selected peer info
	$pDisplay="<div>Select peer to configure</div>";
	if ($p > 0 && $p < 9){
		#set default values
		$pNetwork = 0;
		$pAuth = 0;
		$pAuthKey = "";
		$pIntDead = 40;
		$pIntHello = 10;
		$pIntRetrans = 5;
		$pIntTrans = 120;

		#get values from running config
		@p_byline = `perl /usr/bin/dt/scripts/config-read.pl query run ospfopts $p`;
		foreach my $line (@p_byline){
			chomp($line);
			@p_byval = split(/,/, $line);
		}
		
		#Peer Names
		$pName = $pLink[$p];

		#Network Type
		$pNetwork = $p_byval[1];
    if($pNetwork == 1){
      $pNetworkCheck = "checked";
			$pIntDead = 120;
			$pIntHello = 30;
    }

		#Authenication Type
		$pAuth = $p_byval[2]+1-1;

 		$pAuthTypeStyle="style='background-color: #808080;'";
    $pAuthTypeEn = "disabled";
 		$pAuthKeyStyle="style='background-color: #808080;'";
    $pAuthKeyEn = "readonly";
 		$pAuthMDStyle="style='background-color: #808080;'";
    $pAuthMDEn = "readonly";
    if($pAuth > 0){
	    $pAuthTypeEn = "";
	 		$pAuthTypeStyle="style='background-color: #ffffff;'";
      $pAuthCheck = "checked";
    }
		# Authentication-Key Type
    if($pAuth == 1){
      $pAuthKeyCheck = "checked";
 			$pAuthKeyStyle="style='background-color: #ffffff;'";
	    $pAuthKeyEn = "";
    }
		# NULL Type
    if($pAuth == 2){
      $pAuthCheck = "";
      $pAuthNullCheck = "checked";
 			$pAuthKeyStyle="style='background-color: #ffffff;'";
	    $pAuthKeyEn = "";
    }
		# Message-Digest Type
    if($pAuth == 3){
      $pAuthMDCheck = "checked";
 			$pAuthMDStyle="style='background-color: #ffffff;'";
	    $pAuthMDEn = "";
    }

		#Authentication Key
		if ($p_byval[3] ne "") { $pAuthKey = $p_byval[3]; }

		#Message Digest Key
		if ($p_byval[4]+1-1 > 0) { $pMessKeyID = $p_byval[4]+1-1;}
		if ($p_byval[5] ne "") { $pMessKeyPass = $p_byval[5];}

		#Cost
		if ($p_byval[6]+1-1 > 0) { $pCost = $p_byval[6]+1-1; }

		#Dead-Interval Timer
		if ($p_byval[7]+1-1 > 0) { $pIntDead = $p_byval[7]+1-1; }

		#Hello-Interval Timer
		if ($p_byval[8]+1-1 > 0) { $pIntHello = $p_byval[8]+1-1; }

		#Retransmit-Interval Timer
		if ($p_byval[9]+1-1 > 0) { $pIntRetrans = $p_byval[9]+1-1; }

		#Transmit Delay
		if ($p_byval[10]+1-1 > 0) { $pIntTrans = $p_byval[10]+1-1; }
		
		if (($pIntDead != 40 && $pIntDead != 120 ) ||
				($pIntHello != 10 && $pIntHello != 30 ) ||
				($pIntRetrans != 5 || $pIntTrans != 120 )) {
	    $pDefaultTimersCheck = "checked";
	 		$pIntDeadStyle="style='background-color: #FFFFFF; width: 40px;'";
	 		$pIntHelloStyle="style='background-color: #FFFFFF; width: 40px;'";
	 		$pIntRetransStyle="style='background-color: #FFFFFF; width: 40px;'";
	 		$pIntTransStyle="style='background-color: #FFFFFF; width: 40px;'";
	  }
	  else {
	 		$pIntDeadStyle="style='background-color: #808080; width: 40px;'";
	    $pIntDeadEn = "readonly";
	 		$pIntHelloStyle="style='background-color: #808080; width: 40px;'";
	    $pIntHelloEn = "readonly";
	 		$pIntRetransStyle="style='background-color: #808080; width: 40px;'";
	    $pIntRetransEn = "readonly";
	 		$pIntTransStyle="style='background-color: #808080; width: 40px;'";
	    $pIntTransEn = "readonly";
		}

		#MTU Ignore
		$pMTU = $p_byval[11]+1-1;
		if ($pMTU == 1){
    	$pMTUCheck = "checked";
    }


		#change menu display for selected peer
		$pStyle[$p]="background-color: #BFCFCF; color: #000000;";

		#form display with defaults or with values if returned.
		$pDisplay="<div style='margin: 0px 0px 20px 0px;'>OSPF Peer configuration for " . $pName . "<br></div>".
					"<table class='peer' cellspacing='0' style='float: left'>".

					"<tr><td class='pLabel'>Network:&nbsp;</td><td colspan=2 class='pValue'><input ".$pNetworkCheck." class='pCheck' type='checkbox' value='1' name='pNetwork' id='pNetwork' onClick='setNetworkTimers(this)' /> <i>Point-to-Multipoint</i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=10px></td></tr>".

					"<tr><td class='pLabel'>Authentication:&nbsp;</td><td colspan=2 class='pValue'><input ".$pAuthCheck." class='pCheck' type='checkbox' value='1' name='pAuth' id='pAuth' onClick='setAuthEnable(this)' /> <i>Enable</i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=10px></td></tr>".

					"<tr><td class='pLabel'>Auth Key Type:&nbsp;</td><td colspan=2 class='pValue'><input ".$pAuthKeyCheck." ".$pAuthTypeStyle." ".$pAuthTypeEn." class='pCheck' type='radio' value='1' name='pAuthType' onClick='setAuthType(this)'/> <i>Authentication Key</i><br>".
																																												"<input ".$pAuthNullCheck." ".$pAuthTypeStyle." ".$pAuthTypeEn." class='pCheck' type='radio' value='2' name='pAuthType' onClick='setAuthType(this)'/> <i>null</i><br>".
																																												"<input ".$pAuthMDCheck." ".$pAuthTypeStyle." ".$pAuthTypeEn." class='pCheck' type='radio' value='3' name='pAuthType' onClick='setAuthType(this)'/> <i>message-digest</i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=10px></td></tr>".

					"<tr><td class='pLabel'>Authentication Key:&nbsp;</td><td colspan=2 class='pValue'><input ".$pAuthKeyEn." id='pAuthKey' name='pAuthKey' type='text' value='".$pAuthKey."' maxlength=255 '".$pAuthKeyStyle."' /> <i></i></td></tr>".
					"<tr><td class='pLabel'>Message-digest KeyID:&nbsp;</td><td colspan=2 class='pValue'><input ".$pAuthMDEn." id='pMessKeyID' name='pMessKeyID' type='text' value='".$pMessKeyID."' maxlength=3 '".$pAuthMDStyle."' onKeyDown='return filterNums(event)'/> <i>(min:1 max:255)</i></td></tr>".
					"<tr><td class='pLabel'>Message-digest KeyPass:&nbsp;</td><td colspan=2 class='pValue'><input ".$pAuthMDEn." id='pMessKeyPass' name='pMessKeyPass' type='text' value='".$pMessKeyPass."' maxlength=16 '".$pAuthMDStyle."' /> <i>(max length 16)</i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=10px></td></tr>".

					"<tr><td class='pLabel'>Cost:&nbsp;</td><td colspan=2 class='pValue'><input name='pCost' type='text' value='".$pCost."' maxlength=50 style='width: 40px;' /> <i>(min:1 max:65535)</i></td></tr>".
					"<tr><td class='pLabel'>MTU Ignore:&nbsp;</td><td colspan=2 class='pValue'><input ".$pMTUCheck." class='pCheck' type='checkbox' value='1' name='pMTU' id='pMTU' onClick='' /> <i>(default: disabled)</i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=20px></td></tr>".


					"<tr><td class='pLabel'>Change default timers:&nbsp;</td><td colspan=2 class='pValue'><input ".$pDefaultTimersCheck." class='pCheck' type='checkbox' value='1' name='pDefaultTimers' id='pDefaultTimers' onClick='setTimersEnable(this)' /> <i></i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=5px></td></tr>".
					"<tr><td class='pLabel'>dead-interval:&nbsp;</td><td colspan=2 class='pValue'><input ".$pIntDeadEn." id='pIntDead' name='pIntDead' type='text' value='".$pIntDead."' maxlength=5 '".$pIntDeadStyle."' /> <i>(default:40/120 min:1 max:65535)</i></td></tr>".
					"<tr><td class='pLabel'>hello-interval:&nbsp;</td><td colspan=2 class='pValue'><input ".$pIntHelloEn." id='pIntHello' name='pIntHello' type='text' value='".$pIntHello."' maxlength=5 '".$pIntHelloStyle."' /> <i>(default:10/30 min:1 max:65535)</i></td></tr>".
					"<tr><td class='pLabel'>retransmit-interval:&nbsp;</td><td colspan=2 class='pValue'><input ".$pIntRetransEn." id='pIntRetrans' name='pIntRetrans' type='text' value='".$pIntRetrans."' maxlength=5 '".$pIntRetransStyle."' /> <i>(default:5 min:3 max:65535)</i></td></tr>".
					"<tr><td class='pLabel'>transmit-delay:&nbsp;</td><td colspan=2 class='pValue'><input ".$pIntTransEn." id='pIntTrans' name='pIntTrans' type='text' value='".$pIntTrans."' maxlength=5 '".$pIntTransStyle."' /> <i>(default:120 min:1 max:65535)</i></td></tr>".
					"<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=20px></td></tr>".

					"<tr><td>&nbsp;</td><td colspan=3><input class='pButton' type='submit' value='Commit' name='pCmd'></td>".

					"</table>"
					;

	}
}

sub peerCommit {
	my (@a1);
	$p = $vardata[0];
	if ($p > 0 && $p < 9){
					
		#write OSPF config
		my $cmd = "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write ospfopts ";
		$cmd = $cmd ."\"$p,$spNetwork,$spAuthType,$spAuthKey,$spMessKeyID,$spMessKeyPass,$spCost,$spIntDead,$spIntHello,$spIntRetrans,$spIntTrans,$spMTU\" mod";
		system $cmd;
		
	}

}

