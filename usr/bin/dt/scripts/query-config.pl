use XML::Twig;
use strict;

my $count = 0;
my $eth_ipaddr;
my $eth_subnet;
my $eth_bitmask;
my $eth_mtu;
#my $debug_filename = "/root/router/fs";
my $debug_filename = "";

my $file_name = $debug_filename . '/ftp/config.xml';
my $twig= XML::Twig->new();
$twig->parsefile($file_name);
my $root = $twig->root;


print "\nROUTER START CONFIGURATION\n\n";

#getSystem();
#getETH();
#getRoutes();
getPeers();

sub getSystem {
	foreach my $systems ($root->children('system')){
		print "Hostname: " . $systems->field('hostname') . "\n";
		print "\n";
		open(FH, "> ". $debug_filename . "/etc/HOSTNAME");
		print FH $systems->field('hostname') . "\n";
		close FH; 
	}
}

sub getETH {
	foreach my $ethernet ($root->children('ethernet')){
		$eth_ipaddr = $ethernet->first_child_text('ipaddress');
		$eth_subnet = $ethernet->first_child_text('subnet');
		$eth_bitmask = getbitmask($eth_subnet);
		$eth_mtu = $ethernet->first_child_text('mtu');
		
		print "Ethernet:\n";
	  print " interface: eth0\n";
	  print " IP address: " . $eth_ipaddr . "\n";
	  print " Subnet: " . $eth_subnet . " Bitmask: /" . $eth_bitmask . "\n";
	  print " MTU: " . $eth_mtu . "\n";
	  print "\n";
	
		#dont set.  Zebra will take care of this
		#open(FH, "> $debug_filename . /etc/rc.d/rc.inet1.conf");
		#print FH "IPADDR[0]=" . $ethernet->att('iface') . "\n";
		#print FH "NETMASK[0]=" . $ethernet->first_child_text('ipaddress') . "\n";
		#print FH "MTU[0]=" . $ethernet->first_child_text('mtu') . "\n";
		#close FH;
	}
}

sub getRoutes {
	$count = 0;
	my $static_routes = "";
	my $ospf_routes = "";
	foreach my $route ($root->children('route')){
	  $count += 1;
	  my $type = $route->att('type');
	  my $network = $route->field('network');
	  my $subnet = $route->field('subnet');
	  my $bitmask = 0;
    my $gw;
    my $area;
	  
		print "Route " . $count . "\n";
		print "  type: " . $type . "\n";
		if ($route->children_count('priority') == 1){
			print "  priority: " . $route->att('priority') . "\n";
		}
		if ($route->children_count('default') == 1){
			print "  Default Route\n";
		}
		print "  network: " . $network . "\n";
		print "  subnet: " . $subnet . "\n";
		$bitmask = getbitmask($subnet);
	
		if ($route->children_count('gateway') == 1){
		  $gw = $route->field('gateway');
			print "  gateway: " . $gw . "\n";
		}
		if ($route->children_count('area') == 1){
		  $area = $route->field('area');
			print "  area: " . $area . "\n";
		}
		print "\n";
		
		if ($type eq "static") {
			$static_routes = $static_routes . "ip route " . $network . "/" . $bitmask . " $gw\n";
		}
		if ($type eq "ospf") {
			$ospf_routes = $ospf_routes . "  network " . $network . "/" . $bitmask . " area $area\n";
		}
	}
	
	if (1){
		open(FH, "> ". $debug_filename . "/etc/routing/zebra.conf");
		print FH "! -*- zebra -*-\n\n";
		print FH "password molybdenum\n\n";
		print FH "interface eth0\n";
		print FH "  ip address " . $eth_ipaddr . "/" . $eth_bitmask . "\n\n";
		print FH "interface ppp1\n\n";
		print FH "interface ppp2\n\n";
		print FH "interface ppp3\n\n";
		print FH "interface ppp4\n\n";
		print FH "interface ppp5\n\n";
		print FH "interface ppp6\n\n";
		print FH "interface ppp7\n\n";
		print FH "interface ppp8\n\n";
		print FH $static_routes . "\n";
		print FH "log file /ftp/router.log\n\n";
		close FH;
	}
	if (1){
		open(FH, "> ". $debug_filename . "/etc/routing/ospfd.conf");
		print FH "! -*- OSPF -*-\n\n";
		print FH "password molybdenum\n\n";
		print FH "interface eth0\n";
		print FH "interface ppp1\n\n";
		print FH "interface ppp2\n\n";
		print FH "interface ppp3\n\n";
		print FH "interface ppp4\n\n";
		print FH "interface ppp5\n\n";
		print FH "interface ppp6\n\n";
		print FH "interface ppp7\n\n";
		print FH "interface ppp8\n\n";
		print FH "router ospf\n";
		print FH $ospf_routes . "\n";
		print FH "log file /ftp/router.log\n\n";
		close FH;
	}
	my $zebra_pid;
	my $ospfd_pid;

	$zebra_pid = `/bin/cat /var/run/zebra.pid >> /dev/null`; 
	$zebra_pid=~ s/\n/ /g;

	my $junk_cmd = "/bin/kill -9 " . $zebra_pid . " >> /dev/null 2>&1";
	print "Killing Zebra ". $zebra_pid . "... ";
	system $junk_cmd;
	system "/bin/rm -f /var/run/zebra.pid >> /dev/null 2>&1";
	print "done.\n";

	my $ospfd_pid = `/bin/cat /var/run/ospfd.pid >> /dev/null 2>&1`; 
	$ospfd_pid =~ s/\n/ /g;

	my $junk_cmd = "/bin/kill -9 " . $ospfd_pid . " >> /dev/null 2>&1";
	print "Killing OSPFd ". $ospfd_pid . "... ";
	system $junk_cmd;
	system "/bin/rm -f /var/run/ospfd.pid >> /dev/null 2>&1";
	print "done.\n";

	print "Starting Zebra\n";
	system "/usr/local/sbin/zebra -d -f /etc/routing/zebra.conf";

	print "Starting OSPFd\n";
	system "/usr/local/sbin/ospfd -d -f /etc/routing/ospfd.conf";

}

sub getPeers {
	$count = 0;
	foreach my $peer ($root->children('peer')){
			$count += 1;
			my $peer_name = $peer->first_child_text('name');
			my $peer_localip = $peer->first_child_text('localip');
			my $peer_remoteip = $peer->first_child_text('remoteip');
			my $peer_netmask = $peer->first_child_text('netmask');
			my $peer_number = $peer->first_child_text('number');
			my $peer_username = $peer->first_child_text('username');
			my $peer_password = $peer->first_child_text('password');
			my $peer_mtu = $peer->first_child_text('mtu');
			my $peer_mru = $peer->first_child_text('mru');
			my $peer_persistent = "";
			my $peer_holdoff = $peer->first_child_text('holdoff');
			my $peer_auth = $peer->first_child_text('auth');
			
			
	    print "Peer" . $count . "\n";
	    print " name: " . $peer_name . "\n";
	    print " localip: " . $peer_localip . "\n";
	    print " remoteip: " . $peer_remoteip . "\n";
	    print " netmask: " . $peer_netmask . "\n";
	    print " number: " . $peer_number . "\n";
	    #need an auth check here
	    $peer_auth = $peer_auth +1 -1;
	    if ($peer_auth == 0){
	    	print " auth type(s): none"
	    }
	    if ($peer_auth > 0){
	    	print " auth type: ";
	    	if ($peer_auth & 1){
	    		print "PAP ";
	    	}
	    	if ($peer_auth & 2){
	    		print "CHAP ";
	    	}
	    	if ($peer_auth & 4){
	    		print "MS-CHAP ";
	    	}	    	
	    	print "\n";
	    	print " username: " . $peer_username . "\n";
	    	print " password: *Hidden*\n";
	    }
	    print " mtu: " . $peer_mtu . "\n";
	    print " mru: " . $peer_mtu . "\n";
	    print " persistent: ";
	    if ($peer->children_count('persist') == 1){
				$peer_persistent = "persist";
		    print "yes\n";
	    }	
	    else {
	    	print "no\n";
	    }
	    print " holdoff: " . $peer_holdoff . "\n";
	
	   	my $elt= $peer;
	   	print " chan: ";
	  	while( $elt= $elt->next_elt($peer, 'chan'))
	    { 
	    	my $p = $elt->text;
		    print $p . " ";
	    	open (FH, "> /etc/ppp/peers/isdn/bch".$p);
	    	print FH "# -*- B Channel " . $p . " -*-\n\n";
	    	print FH "# Name: ". $peer_name  ."\n\n";
				print FH "debug\n";
				print FH "logfile /ftp/ppp-bchan". $p .".log\n";
				print FH "unit ". $p ."\n";
				print FH "sync\n";
				print FH "plugin capiplugin.so\n";
				print FH "controller 1\n";
				print FH "multilink\n";
				print FH "protocol hdlc\n";
				print FH "number ". $peer_number . "\n";
				print FH $peer_localip .":". $peer_remoteip ."\n";
				print FH "netmask ". $peer_netmask ."\n";
				if ($peer_auth == 0 ){
					print FH "noauth\n";
				}
				else {
					print FH "auth\n";
				}
				if ($peer_auth & 1 ){}
				else {
					print FH "refuse-pap\n";
				}
				if ($peer_auth & 2 ){}
				else {
					print FH "refuse-chap\n";
				}
				if ($peer_auth & 4 ){}
				else {
					print FH "refuse-mschap\n";
				}
				
				if ($peer_persistent ne ""){
					print FH $peer_persistent ."\n";
					print FH "holdoff ". $peer_holdoff ."\n";
					print FH "dialmax 100\n";
				}
				else {
					print FH "dialmax 3\n";
				}
				
				print FH "noccp\n";
				print FH "novj\n";
				print FH "ipcp-accept-local\n";
				print FH "ipcp-accept-remote\n";
				print FH "mtu ". $peer_mtu ."\n";
				print FH "mru ". $peer_mru ."\n";
				print FH "/dev/null\n";
	    	close FH;
	    	if ($peer_persistent eq "persist"){
	    		system "/usr/sbin/pppd call isdn/bch". $p;
	    	}
	    }
	    print "\n";
	    print "\n";
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

exit 0;