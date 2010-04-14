#! /usr/bin/perl -W
# Main page for the router.  Shows a brief summary of interfaces.
#
use strict;
use warnings;
use CGI;
use CGI::Ajax;
use IO::File;
require include::CheckConfig;


use vars qw(
	@varname @vardata $line @values $ok $cfgdiff $IP_Prefs $maxvar $test
	$uname $rtr_hostname
	@iface_status $iface_dhcp_yes $iface_dhcp_no @iface_ipaddr @iface_netmask @iface_gw @iface_dns1 @iface_dns2 $iface_mtu
);

getEnv();

if ($vardata[$maxvar] eq "Commit"){
	doStuff();
}
$cfgdiff = CheckConfig::Check();
getInfo();
getETH(0);


my $cgi = CGI->new();
my $ajax = CGI::Ajax->new( 'getEnv' => \&getEnv );
print $ajax->build_html ( $cgi, \&main );

sub main {
	my $html = <<EOHTML;
	<html>
	<head>
		<title>DTECH Labs - Router</title>
		<link href='../css/style.css' rel='stylesheet' type='text/css'>
		<!--
		<script language='javascript'>
			function setDisable(obj)
			{
				if(obj.value == 0)
				{
					document.forms[0].eth_ipaddr1.style.backgroundColor = "#ffffff";
					document.forms[0].eth_ipaddr1.readOnly = 0;
					document.forms[0].eth_ipaddr2.style.backgroundColor = "#ffffff";
					document.forms[0].eth_ipaddr2.readOnly = 0;
					document.forms[0].eth_ipaddr3.style.backgroundColor = "#ffffff";
					document.forms[0].eth_ipaddr3.readOnly = 0;
					document.forms[0].eth_ipaddr4.style.backgroundColor = "#ffffff";
					document.forms[0].eth_ipaddr4.readOnly = 0;

					document.forms[0].eth_netmask1.style.backgroundColor = "#ffffff";
					document.forms[0].eth_netmask1.readOnly = 0;
					document.forms[0].eth_netmask2.style.backgroundColor = "#ffffff";
					document.forms[0].eth_netmask2.readOnly = 0;
					document.forms[0].eth_netmask3.style.backgroundColor = "#ffffff";
					document.forms[0].eth_netmask3.readOnly = 0;
					document.forms[0].eth_netmask4.style.backgroundColor = "#ffffff";
					document.forms[0].eth_netmask4.readOnly = 0;
				} else {
					document.forms[0].eth_ipaddr1.style.backgroundColor = "#808080";
					document.forms[0].eth_ipaddr1.readOnly = 1;
					document.forms[0].eth_ipaddr2.style.backgroundColor = "#808080";
					document.forms[0].eth_ipaddr2.readOnly = 1;
					document.forms[0].eth_ipaddr3.style.backgroundColor = "#808080";
					document.forms[0].eth_ipaddr3.readOnly = 1;
					document.forms[0].eth_ipaddr4.style.backgroundColor = "#808080";
					document.forms[0].eth_ipaddr4.readOnly = 1;

					document.forms[0].eth_netmask1.style.backgroundColor = "#808080";
					document.forms[0].eth_netmask1.readOnly = 1;
					document.forms[0].eth_netmask2.style.backgroundColor = "#808080";
					document.forms[0].eth_netmask2.readOnly = 1;
					document.forms[0].eth_netmask3.style.backgroundColor = "#808080";
					document.forms[0].eth_netmask3.readOnly = 1;
					document.forms[0].eth_netmask4.style.backgroundColor = "#808080";
					document.forms[0].eth_netmask4.readOnly = 1;
				}
			}
		</script>
		// -->
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
			<a id='menuLink' href='isdn.pl'>ISDN</a>&nbsp;
			<a id='menuLink' href='routing.pl'>routing</a>&nbsp;
			<a id='menuLink' href='security.pl'>security</a>&nbsp;
			<a id='menuLink' href='admin.pl'>admin</a>
		</div>
		$cfgdiff
		<div id='content'>
			<h2>Ethernet Configuration</h2>
			<div id='colFull'>
				<fieldset style='height: 400px;'>
					<legend>Ethernet Interface</legend>
					<br><img src='../images/spacer.gif' width=1px height=10px>
				<form action="ethernet.pl" method="POST">
					<table class='eth' cellspacing='0'  style='border: 1px; float: left'>
					<tr><td class='pLabel'>Hostname: </td><td class='pValue'><input name='rtr_hostname' type='text' value='$rtr_hostname' style='width: 135px;'/></td></tr>
					<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=13px></td></tr>


					<tr><td class='pLabel'>IP Address: </td><td class='pValue'><input name='eth_ipaddr1' type='text' value='$iface_ipaddr[1]' maxlength=3 style='width: 30px;' />.<input name='eth_ipaddr2' type='text' value='$iface_ipaddr[2]' maxlength=3 style='width: 30px'/>.<input name='eth_ipaddr3' type='text' value='$iface_ipaddr[3]' maxlength=3 style='width: 30px'/>.<input name='eth_ipaddr4' type='text' value='$iface_ipaddr[4]' maxlength=3 style='width: 30px'/></td></tr>
					<tr><td class='pLabel'>Subnet Mask: </td><td class='pValue'><input name='eth_netmask1' type='text' value='$iface_netmask[1]' maxlength=3 style='width: 30px;' />.<input name='eth_netmask2' type='text' value='$iface_netmask[2]' maxlength=3 style='width: 30px'/>.<input name='eth_netmask3' type='text' value='$iface_netmask[3]'maxlength=3 style='width: 30px'/>.<input name='eth_netmask4' type='text' value='$iface_netmask[4]' maxlength=3 style='width: 30px'/></td></tr>
					<tr><td class='pLabel'>MTU: </td><td class='pValue'><input name='eth_mtu' type='text' value='$iface_mtu' maxlength=5 style='width: 64px;' /></td></tr>
					<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=10px></td></tr>

					<tr><td colspan=2><img src='../images/spacer.gif' width=1px height=10px></td></tr>

					<tr><td>&nbsp;</td<td class='pLabel'><input class='pButton' type="submit" value="Commit" name="pCmd"></td></tr>
					</table>
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
	<br><br>$test
	</body>
	</html>
EOHTML

	return $html;
}


sub getEnv {
	my($i, $a, $eline, $name);
	read(STDIN, $eline, $ENV{'CONTENT_LENGTH'});
	@values = split(/&/, $eline);
	$a=0;
	foreach $i(@values) {
		$maxvar = $a;
		($name, $vardata[$a]) = split(/=/, $i);
		$vardata[$a] =~ tr/+/ /;
		$vardata[$a] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$a++;
	}
}

sub doStuff {
	my(@run, $cmd, $hostname, $dhcp, $ipaddr, $subnet, $dns1, $dns2, $mtu);
	$ok = 0;
	if ($vardata[0] ne "")
	{
		$hostname = $vardata[0];
		$ok = 1;
	}
	else { $ok =0; }

	if (($vardata[1] >= 0 && $vardata[1] <= 255) &&
			($vardata[2] >= 0 && $vardata[2] <= 255) &&
			($vardata[3] >= 0 && $vardata[3] <= 255) &&
			($vardata[4] >= 0 && $vardata[4] <= 255) &&
			($ok == 1))
	{
		$ipaddr	= $vardata[1].".".$vardata[2].".".$vardata[3].".".$vardata[4];
		$ok = 1;
	}
	else { $ok =0; }

	if (($vardata[5] >= 0 && $vardata[5] <= 255) &&
			($vardata[6] >= 0 && $vardata[6] <= 255) &&
			($vardata[7] >= 0 && $vardata[7] <= 255) &&
			($vardata[8] >= 0 && $vardata[8] <= 255) &&
			($ok == 1))
	{
		$subnet	= $vardata[5].".".$vardata[6].".".$vardata[7].".".$vardata[8];
		$ok = 1;
	}
	else { $ok =0; }

	if ($vardata[9] >=60 && $vardata[9] <=1500 && $ok == 1){
		$mtu = $vardata[9];
		$ok = 1;
	}

	if (($vardata[10] >= 0 && $vardata[10] <= 255) &&
			($vardata[11] >= 0 && $vardata[11] <= 255) &&
			($vardata[12] >= 0 && $vardata[12] <= 255) &&
			($vardata[13] >= 0 && $vardata[13] <= 255) &&
			($ok == 1))
	{
		$dns1 	= $vardata[10].".".$vardata[11].".".$vardata[12].".".$vardata[13];
		$ok = 1;
	}
	else { $ok =0; }

	if (($vardata[14] >= 0 && $vardata[14] <= 255) &&
			($vardata[15] >= 0 && $vardata[15] <= 255) &&
			($vardata[16] >= 0 && $vardata[16] <= 255) &&
			($vardata[17] >= 0 && $vardata[17] <= 255) &&
			($ok == 1))
	{
		$dns2 = $vardata[14].".".$vardata[15].".".$vardata[16].".".$vardata[17];
		$ok = 1;
	}
	else { $ok =0; }

	#set hostname
	if ($ok == 1){
		system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write run sys $hostname";
	}

	# check for DHCP the set ip addresses
	if ($dhcp == 0 && $ok == 1){
		#$test = "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write eth \"0,$ipaddr,$subnet,$mtu\" mod";
		system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write eth \"0,$ipaddr,$subnet,$mtu\" mod";
	}
}


sub getInfo {
	$uname=`uptime`;
	$rtr_hostname = "n/a";
	$rtr_hostname = `cat /etc/hostname`;
}


sub getETH ($) {
	my($i, @a1, @a2, @a3, @a4, $item, $x);
	$i = $_[0];
	$iface_dhcp_yes = "";
	$iface_dhcp_no = "checked";
	$iface_ipaddr[1] = 0;
	$iface_ipaddr[2] = 0;
	$iface_ipaddr[3] = 0;
	$iface_ipaddr[4] = 0;
	$iface_netmask[1] = 0;
	$iface_netmask[2] = 0;
	$iface_netmask[3] = 0;
	$iface_netmask[4] = 0;
	$iface_dns1[1] = 0;
	$iface_dns1[2] = 0;
	$iface_dns1[3] = 0;
	$iface_dns1[4] = 0;
	$iface_dns2[1] = 0;
	$iface_dns2[2] = 0;
	$iface_dns2[3] = 0;
	$iface_dns2[4] = 0;
	$iface_mtu = 1500;

	if (-e "/etc/dhcpc/dhcpcd-eth0.pid")
	{
		$iface_dhcp_yes = "checked";
		$iface_dhcp_no = "";
	}
	if (-e "/proc/sys/net/ipv4/conf/eth0"){

		#get iface_ipaddr from ifconfig
		my $ifconfig = `/sbin/ifconfig eth0 | grep -w inet`;
		@a1 = split(/\ /, $ifconfig);
		@a2 = split(/\:/, $a1[11]);
		$iface_ipaddr[0] = $a2[1];
		#iface_ipaddr
		@a2 = split(/\./, $iface_ipaddr[0]);
		$iface_ipaddr[1] = $a2[0];
		$iface_ipaddr[2] = $a2[1];
		$iface_ipaddr[3] = $a2[2];
		$iface_ipaddr[4] = $a2[3];

		#get iface_netmask from ifconfig
		@a2 = split(/\:/, $a1[15]);
		$iface_netmask[0] = $a2[1];		
		@a2 = split(/\./, $iface_netmask[0]);
		$iface_netmask[1] = $a2[0];
		$iface_netmask[2] = $a2[1];
		$iface_netmask[3] = $a2[2];
		$iface_netmask[4] = $a2[3];

		#get iface_mtu
		$ifconfig = `/sbin/ifconfig eth0 | grep MTU`;
		@a1 = split(/\ /, $ifconfig);
		@a2 = split(/\:/, $a1[15]);
		$iface_mtu = $a2[1];
		
		if (-e "/etc/resolv.conf")
		{
			#get iface_dns1 from /etc/resolv.conf
			@a1 = `cat /etc/resolv.conf | grep nameserver`;
			@a2 = split(/ /,$a1[0]);
			$iface_dns1[0] = $a2[1];
			@a3 = split(/\./, $iface_dns1[0]);
			$iface_dns1[1] = $a3[0];
			$iface_dns1[2] = $a3[1];
			$iface_dns1[3] = $a3[2];
			$iface_dns1[4] = $a3[3];

			#get iface_dns1 from /etc/resolv.conf
			@a1 = `cat /etc/resolv.conf | grep nameserver`;
			@a2 = split(/ /,$a1[1]);
			$iface_dns2[0] = $a2[1];
			@a3 = split(/\./, $iface_dns2[0]);
			$iface_dns2[1] = $a3[0];
			$iface_dns2[2] = $a3[1];
			$iface_dns2[3] = $a3[2];
			$iface_dns2[4] = $a3[3];
		}
		$#a1 = 0;
		$#a2 = 0;
		$#a3 = 0;

	}
}

sub getbitmask {
	my $subnet = shift;
	my $bitmask = -1;

	if ($subnet eq "0.0.0.0") { $bitmask = 0 };
	if ($subnet eq "255.0.0.0") { $bitmask = 8 };
	if ($subnet eq "255.128.0.0") { $bitmask = 9 };
	if ($subnet eq "255.192.0.0") { $bitmask = 10 };
	if ($subnet eq "255.224.0.0") { $bitmask = 11 };
	if ($subnet eq "255.240.0.0") { $bitmask = 12 };
	if ($subnet eq "255.248.0.0") { $bitmask = 13 };
	if ($subnet eq "255.252.0.0") { $bitmask = 14 };
	if ($subnet eq "255.254.0.0") { $bitmask = 15 };
	if ($subnet eq "255.255.0.0") { $bitmask = 16 };
	if ($subnet eq "255.255.128.0") { $bitmask = 17 };
	if ($subnet eq "255.255.192.0") { $bitmask = 18 };
	if ($subnet eq "255.255.224.0") { $bitmask = 19 };
	if ($subnet eq "255.255.240.0") { $bitmask = 20 };
	if ($subnet eq "255.255.248.0") { $bitmask = 21 };
	if ($subnet eq "255.255.252.0") { $bitmask = 22 };
	if ($subnet eq "255.255.254.0") { $bitmask = 23 };
	if ($subnet eq "255.255.255.0") { $bitmask = 24 };
	if ($subnet eq "255.255.255.128") { $bitmask = 25 };
	if ($subnet eq "255.255.255.192") { $bitmask = 26 };
	if ($subnet eq "255.255.255.224") { $bitmask = 27 };
	if ($subnet eq "255.255.255.240") { $bitmask = 28 };
	if ($subnet eq "255.255.255.248") { $bitmask = 29 };
	if ($subnet eq "255.255.255.252") { $bitmask = 30 };
	return $bitmask;
}