#! /usr/bin/perl -W
# Main page for the router.  Shows a brief summary of interfaces.
#
use strict;
use warnings;
use CGI;
use CGI::Ajax;
require include::CheckConfig;

use vars qw(
	$uname	$rtr_hostname	$rtr_model	$rtr_fsversion $cfgdiff
	$service_udhcpd	$service_zebra	$service_ospfd	$service_bgpd	$service_ripd	$service_eigrpd
	@iface_status	@iface_name	@iface_hwaddr	@iface_ipaddr	@iface_bcast	@iface_netmask	@iface_mtu	@iface_rxpacket
	@iface_rxerrors	@iface_rxdropped	@iface_rxoverrun	@iface_rxframe	@iface_txpacket	@iface_txerrors	@iface_txdropped
	@iface_txoverrun	@iface_txcarrier	@iface_collisions	@iface_rxbytes	@iface_txbytes	@iface_rxunits	@iface_txunits
);
$cfgdiff = CheckConfig::Check();

my $cgi = CGI->new();
my $ajax = CGI::Ajax->new( 'getETH' => \&getETH );
print $ajax->build_html ( $cgi, \&main );

sub main {
	getInfo();
	getServices();
	getETH(0);
	getETH(1);

	my $html = <<EOHTML;
	<html>
	<head>
		<title>DTECH Labs - Router</title>
		<link href='./css/style.css' rel='stylesheet' type='text/css'>
	</head>
	<body>
	<center>
	<div id='wrapper'>
		<div id='header'>
			<div id='logo'>
				<img src='images/banner100.jpg'>
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
			<h2>System Information</h2>
			<div id='col0'>
				<fieldset>
					<legend>Router</legend>
					<div id='setting'><span id='label'>Hostname: </span>$rtr_hostname</div>
					<div id='setting'><span id='label'>Model: </span>$rtr_model</div>
					<div id='setting'><span id='label'>Firmware: </span>$rtr_fsversion</div>
					<img src='images/spacer.gif' width=1px height=30px>
				</fieldset>
			</div>
			<div id='col1'>
				<fieldset style='height:80px;'>
					<legend>Services</legend>
					<div id='setting'><span id='label'>Static Router: </span>$service_zebra</div>
					<div id='setting'><span id='label'>OSPF Router: </span>$service_ospfd</div>
				</fieldset>
			</div>	<br clear='all'>
			<h2>Ethernet Information</h2>
			<div id='col0'>
				<fieldset>
					<legend>$iface_name[0]</legend>
					<div id='setting'><span id='label'>Status: </span>$iface_status[0]</div>
					<img src='images/spacer.gif' width=1px height=6px>
					<div id='setting'><span id='label'>MAC Address: </span>$iface_hwaddr[0]</div>
					<div id='setting'><span id='label'>IP Address: </span>$iface_ipaddr[0]</div>
					<div id='setting'><span id='label'>IP Broadcast: </span>$iface_bcast[0]</div>
					<div id='setting'><span id='label'>IP Netmask: </span>$iface_netmask[0]</div>
				</fieldset>
				<fieldset>
					<legend>$iface_name[0] - statistics</legend>
					<div id='setting'><span id='label'>RX Bytes: </span>$iface_rxbytes[0] $iface_rxunits[0]</div>
					<div id='setting'><span id='label'>TX Bytes: </span>$iface_txbytes[0] $iface_txunits[0]</div>
					<img src='images/spacer.gif' width=1px height=6px>
					<div id='setting'><span id='label'>RX Errors: </span>$iface_rxerrors[0]</div>
					<div id='setting'><span id='label'>TX Errors: </span>$iface_txerrors[0]</div>
					<img src='images/spacer.gif' width=1px height=6px>
					<div id='setting'><span id='label'>RX Dropped: </span>$iface_rxdropped[0]</div>
					<div id='setting'><span id='label'>TX Dropped: </span>$iface_txdropped[0]</div>
				</fieldset>
			</div>
			<div id='col1'>
				<fieldset>
					<legend>$iface_name[1]</legend>
					<div id='setting'><span id='label'>Status: </span>$iface_status[1]</div>
					<img src='images/spacer.gif' width=1px height=6px>
					<div id='setting'><span id='label'>MAC Address: </span>$iface_hwaddr[1]</div>
					<div id='setting'><span id='label'>IP Address: </span>$iface_ipaddr[1]</div>
					<div id='setting'><span id='label'>IP Broadcast: </span>$iface_bcast[1]</div>
					<div id='setting'><span id='label'>IP Netmask: </span>$iface_netmask[1]</div>
				</fieldset>
				<fieldset>
					<legend>$iface_name[1] - statistics</legend>
					<div id='setting'><span id='label'>RX Bytes: </span>$iface_rxbytes[1] $iface_rxunits[1]</div>
					<div id='setting'><span id='label'>TX Bytes: </span>$iface_txbytes[1] $iface_txunits[1]</div>
					<img src='images/spacer.gif' width=1px height=6px>
					<div id='setting'><span id='label'>RX Errors: </span>$iface_rxerrors[1]</div>
					<div id='setting'><span id='label'>TX Errors: </span>$iface_txerrors[1]</div>
					<img src='images/spacer.gif' width=1px height=6px>
					<div id='setting'><span id='label'>RX Dropped: </span>$iface_rxdropped[1]</div>
					<div id='setting'><span id='label'>TX Dropped: </span>$iface_txdropped[1]</div>
				</fieldset>
			</div>
		</div>
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
	my(@a);
	$uname=`uptime`;
	$rtr_hostname = "n/a";
	$rtr_model = "n/a";
	$rtr_fsversion = "n/a";

	$rtr_hostname = `cat /etc/hostname`;
	$rtr_model = `cat /.model`;
	$rtr_fsversion = `cat /.version`;

	$uname=`uptime`;

}
sub getServices {
	$service_udhcpd = "DOWN";
	$service_zebra = "DOWN";
	$service_ospfd = "DOWN";
	$service_bgpd = "DOWN";
	$service_ripd = "DOWN";
	$service_eigrpd = "DOWN";

	if (-e "/var/run/udhcpd.pid"){
			$service_udhcpd = "UP";
	}
	if (-e "/var/run/zebra.pid"){
			$service_zebra = "UP";
		if (-e "/var/run/ospfd.pid"){
			$service_ospfd = "UP";
		}
		if (-e "/var/run/ripd.pid"){
			$service_ripd = "UP";
		}
		if (-e "/var/run/bgpd.pid"){
			$service_bgpd = "UP";
		}
		if (-e "/var/runeigrpd.pid"){
			$service_eigrpd = "UP";
		}
	}
}

sub getETH ($) {
	my($i, @a1, @a2, @a3, $item, $x);
	$i = $_[0];
	$iface_status[$i] = "n/a";
	$iface_name[$i] = "n/a";
	$iface_hwaddr[$i] = "n/a";
	$iface_ipaddr[$i] = "n/a";
	$iface_bcast[$i] = "n/a";
	$iface_netmask[$i] = "n/a";
	$iface_mtu[$i] = "n/a";
	$iface_rxpacket[$i] = "n/a";
	$iface_rxerrors[$i] = "n/a";
	$iface_rxdropped[$i] = "n/a";
	$iface_rxoverrun[$i] = "n/a";
	$iface_rxframe[$i] = "n/a";
	$iface_txpacket[$i] = "n/a";
	$iface_txerrors[$i] = "n/a";
	$iface_txdropped[$i] = "n/a";
	$iface_txoverrun[$i] = "n/a";
	$iface_txcarrier[$i] = "n/a";
	$iface_collisions[$i] = "n/a";
	$iface_rxbytes[$i] = "n/a";
	$iface_txbytes[$i] = "n/a";

	if ($i == 0){
		if (-e "/proc/sys/net/ipv4/conf/eth0") {
			@a1 = `/sbin/ifconfig eth0`;
			#get iface_name and iface_hwaddr
			@a2 = split(/ /,$a1[0]);		# split line 1 of a1 on spaces

			$iface_name[$i] = $a2[0];
			$iface_hwaddr[$i] = $a2[10];
			$#a2 = 0;
			$#a3 = 0;

			#get iface_ipaddr, iface_bcast, iface_netmask
			@a2 = split(/ /,$a1[1]);		# split line 2 of a1 on spaces
			@a3 = split(/:/,$a2[11]);			# split sa2 on colon
			$iface_ipaddr[$i] = $a3[1];
			@a3 = split(/:/,$a2[13]);
			$iface_bcast[$i] = $a3[1];
			@a3 = split(/:/,$a2[15]);
			$iface_netmask[$i] = $a3[1];
			$iface_rxframe[$i] = $a3[1];;
			$#a2 = 0;
			$#a3 = 0;

			#get iface_mtu
			@a2 = split(/ /,$a1[2]);
			@a3 = split(/:/,$a2[15]);
			$iface_mtu[$i] = $a3[1];
			if ($a2[10] eq "UP") {
				if ($a2[12] eq "RUNNING")||($a2[12] eq "RUNNING") {
					$iface_status[$i] = "UP/CONNECTED";
				}
				if ($a2[12] ne "RUNNING")&&($a2[12] ne "RUNNING"){
					$iface_status[$i] = "UP/DISCONNECTED";
				}
			}else{
				$iface_status[$i] = "Administratively Down";
			}
			$#a2 = 0;
			$#a3 = 0;

			#get iface_rxpackets, iface_rxerrors, iface_dropped, iface_rxoverrun, iface_rxframe
			@a2 = split(/ /,$a1[3]);
			@a3 = split(/:/,$a2[11]);
			$iface_rxpacket[$i] = $a3[1];;
			@a3 = split(/:/,$a2[12]);
			$iface_rxerrors[$i] = $a3[1];;
			@a3 = split(/:/,$a2[13]);
			$iface_rxdropped[$i] = $a3[1];;
			@a3 = split(/:/,$a2[14]);
			$iface_rxoverrun[$i] = $a3[1];;
			@a3 = split(/:/,$a2[15]);
			$#a2 = 0;
			$#a3 = 0;

			#get iface_rxpackets, iface_rxerrors, iface_dropped, iface_rxoverrun, iface_rxframe
			@a2 = split(/ /,$a1[4]);
			@a3 = split(/:/,$a2[11]);
			$iface_txpacket[$i] = $a3[1];;
			@a3 = split(/:/,$a2[12]);
			$iface_txerrors[$i] = $a3[1];;
			@a3 = split(/:/,$a2[13]);
			$iface_txdropped[$i] = $a3[1];;
			@a3 = split(/:/,$a2[14]);
			$iface_txoverrun[$i] = $a3[1];;
			@a3 = split(/:/,$a2[15]);
			$iface_txcarrier[$i] = $a3[1];;
			$x=0;
			$#a2 = 0;
			$#a3 = 0;

			#get iface_collisions
			@a2 = split(/ /,$a1[5]);
			@a3 = split(/:/,$a2[10]);
			$iface_collisions[$i] = $a3[1];;
			$#a2 = 0;
			$#a3 = 0;

			#get iface_rxbytes, iface_txbytes
			@a2 = split(/ /,$a1[6]);
			@a3 = split(/:/,$a2[11]);
			$iface_rxbytes[$i] = $a3[1];
			@a3 = split(/:/,$a2[16]);
			$iface_txbytes[$i] = $a3[1];
			formatBytes($i);
		}
	}
	else {
		if ($i == 1){
		if (-e "/proc/sys/net/ipv4/conf/ppp0"){
			@a1 = `/sbin/ifconfig ppp0`;
			#get iface_name and iface_hwaddr
			@a2 = split(/ /,$a1[0]);		# split line 1 of a1 on spaces

			$iface_name[$i] = $a2[0];
			#$iface_hwaddr[$i] = $a2[10];
			$#a2 = 0;
			$#a3 = 0;

			#get iface_ipaddr, iface_bcast, iface_netmask
			@a2 = split(/ /,$a1[1]);		# split line 2 of a1 on spaces
			@a3 = split(/:/,$a2[11]);			# split sa2 on colon
			$iface_ipaddr[$i] = $a3[1];
			@a3 = split(/:/,$a2[13]);
			$iface_bcast[$i] = $a3[1];
			@a3 = split(/:/,$a2[15]);
			$iface_netmask[$i] = $a3[1];
			$iface_rxframe[$i] = $a3[1];;
			$#a2 = 0;
			$#a3 = 0;

			#get iface_mtu
			@a2 = split(/ /,$a1[2]);
			@a3 = split(/:/,$a2[15]);
			$iface_mtu[$i] = $a3[1];
			if ($a2[10] eq "UP") {
				if ($a2[12] eq "RUNNING"){
					$iface_status[$i] = "UP/CONNECTED";
				}
				if ($a2[12] ne "RUNNING"){
					$iface_status[$i] = "UP/DISCONNECTED";
				}
			}else{
				$iface_status[$i] = "Administratively Down";
			}
			$#a2 = 0;
			$#a3 = 0;

			#get iface_rxpackets, iface_rxerrors, iface_dropped, iface_rxoverrun, iface_rxframe
			@a2 = split(/ /,$a1[3]);
			@a3 = split(/:/,$a2[11]);
			$iface_rxpacket[$i] = $a3[1];;
			@a3 = split(/:/,$a2[12]);
			$iface_rxerrors[$i] = $a3[1];;
			@a3 = split(/:/,$a2[13]);
			$iface_rxdropped[$i] = $a3[1];;
			@a3 = split(/:/,$a2[14]);
			$iface_rxoverrun[$i] = $a3[1];;
			@a3 = split(/:/,$a2[15]);
			$#a2 = 0;
			$#a3 = 0;

			#get iface_rxpackets, iface_rxerrors, iface_dropped, iface_rxoverrun, iface_rxframe
			@a2 = split(/ /,$a1[4]);
			@a3 = split(/:/,$a2[11]);
			$iface_txpacket[$i] = $a3[1];;
			@a3 = split(/:/,$a2[12]);
			$iface_txerrors[$i] = $a3[1];;
			@a3 = split(/:/,$a2[13]);
			$iface_txdropped[$i] = $a3[1];;
			@a3 = split(/:/,$a2[14]);
			$iface_txoverrun[$i] = $a3[1];;
			@a3 = split(/:/,$a2[15]);
			$iface_txcarrier[$i] = $a3[1];;
			$x=0;
			$#a2 = 0;
			$#a3 = 0;

			#get iface_collisions
			@a2 = split(/ /,$a1[5]);
			@a3 = split(/:/,$a2[10]);
			$iface_collisions[$i] = $a3[1];;
			$#a2 = 0;
			$#a3 = 0;

			#get iface_rxbytes, iface_txbytes
			@a2 = split(/ /,$a1[6]);
			@a3 = split(/:/,$a2[11]);
			$iface_rxbytes[$i] = $a3[1];
			@a3 = split(/:/,$a2[16]);
			$iface_txbytes[$i] = $a3[1];
			formatBytes($i);
		}
	}}

}

sub formatBytes {
	my ($i);
	$i = $_[0];
	$iface_rxbytes[$i]=$iface_rxbytes[$i];
	$iface_rxunits[$i] = "bytes";
	if ($iface_rxbytes[$i] > 1024) {
		$iface_rxbytes[$i] = $iface_rxbytes[$i] / 1024;
		$iface_rxunits[$i] = "Kbytes";
		if ($iface_rxbytes[$i] > 1024) {
			$iface_rxbytes[$i] = $iface_rxbytes[$i] / 1024;
			$iface_rxunits[$i] = "Mbytes";
		}
		$iface_rxbytes[$i]=sprintf("%.2f", $iface_rxbytes[$i]);
	}

	$iface_txbytes[$i]=$iface_txbytes[$i];
	$iface_txunits[$i] = "bytes";
	if ($iface_txbytes[$i] > 1024) {
		$iface_txbytes[$i] = $iface_txbytes[$i] / 1024;
		$iface_txunits[$i] = "Kbytes";
		if ($iface_txbytes[$i] > 1024) {
			$iface_txbytes[$i] = $iface_txbytes[$i] / 1024;
			$iface_txunits[$i] = "Mbytes";
		}
		$iface_txbytes[$i]=sprintf("%.2f", $iface_txbytes[$i]);
	}
}
