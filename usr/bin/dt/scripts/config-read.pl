use XML::Twig;
use strict;

my $args = $#ARGV + 1;

my $eth_ipaddr;
my $eth_subnet;
my $eth_bitmask;
my $eth_mtu;
#my $debug_filename = "/root/router/fs";
my $debug_filename = "";
my $file_name = "";
my $file_name_start = $debug_filename . '/ftp/config.xml';
my $file_name_run = $debug_filename . '/ftp/config-run.xml';
my $tmp_filename = $debug_filename . "/ftp/.cfgdiff";
my $root = "";
my $action;


##
## Args
##	0 - What are we doing: startup, query, write, dial, hang
##  1 - Which config to query: start, run
##  2 - Which section to query: sys, eth, route, peers
##
if ($args == 0) {
	print "Requires arguments,\n\n";
	print "Args\n";
	print "  0 - What are we doing: startup, query, save, write, dial\n";
	print "  1 - Which config to query: start, run\n";
	print "  2 - What to handle: sys, eth, route, peers\n\n";

}
$action = $ARGV[0];

if ($action eq "startup"){
	my $twig= XML::Twig->new();
	$file_name = $file_name_start;
	$twig->parsefile($file_name);
	$root = $twig->root;

	print "\nROUTER START CONFIGURATION\n\n";
	doSystem();
	doETH();
	doRoutes();
	doPeers();
	print "Copy startup config to running config\n\n";
	exec `/bin/cp $file_name $file_name_run`;
	if (-e $tmp_filename) { exec `/bin/rm $tmp_filename`; }
}

if ($action eq "save"){
	exec `/bin/cp $file_name_run $file_name_start`;
	if (-e $tmp_filename){ exec `/bin/rm $tmp_filename`;	}
}


if ($action eq "query"){
	my $twig= XML::Twig->new();
	#Which config to query
	if ($ARGV[1] eq ""){
		exit 0;
	}
	if ($ARGV[1] eq "start") {
		$file_name = $file_name_start;
	}
	if ($ARGV[1] eq "run") {
		$file_name = $file_name_run;
	}
	
	$twig->parsefile($file_name);
	$root = $twig->root;
	
	#Which section to report
	if ($ARGV[2] eq "sys") {
		qrySystem();
	}
	if ($ARGV[2] eq "eth") {
		qryETH();
	}
	if ($ARGV[2] eq "route") {
		qryRoutes();
	}
	if ($ARGV[2] eq "ospfopts") {
		qryOSPFOpt();
	}
	if ($ARGV[2] eq "peers") {
		qryPeers();
	}
}

if ($action eq "write"){
	my $twig= XML::Twig->new();
	#Which config to query
	if ($ARGV[1] eq ""){
		exit 0;
	}
	if ($ARGV[1] eq "start") {
		$file_name = $file_name_start;
	}
	if ($ARGV[1] eq "run") {
		$file_name = $file_name_run;
	}	
	$twig->parsefile($file_name);
	$root = $twig->root;
	
	#Which section to write
	if ($ARGV[2] eq "sys") {
		doSystem();
	}
	if ($ARGV[2] eq "eth") {
		doETH();
		doRoutes();
	}
	if ($ARGV[2] eq "route") {
		doETH();
		doRoutes();
	}
	if ($ARGV[2] eq "ospfopts") {
		doOSPFOpt();
	}
	if ($ARGV[2] eq "peers") {
		doPeers();
	}
}

if ($action eq "dial"){
	my $twig= XML::Twig->new();
	#Which config to query
	if ($ARGV[1] eq ""){
		exit 0;
	}
	if ($ARGV[1] eq "start") {
		$file_name = $file_name_start;
	}
	if ($ARGV[1] eq "run") {
		$file_name = $file_name_run;
	}	
	$twig->parsefile($file_name);
	$root = $twig->root;
	
	#Which peer to dial
	if ($ARGV[2] eq ""){
		exit 0;
	}
	if (($ARGV[2] eq "peer") && ($ARGV[3] ne "")) {
		dialPeers($ARGV[3]);
	}
}

if ($action eq "hang"){
	my $twig= XML::Twig->new();
	#Which config to query
	if ($ARGV[1] eq ""){
		exit 0;
	}
	if ($ARGV[1] eq "start") {
		$file_name = $file_name_start;
	}
	if ($ARGV[1] eq "run") {
		$file_name = $file_name_run;
	}	
	$twig->parsefile($file_name);
	$root = $twig->root;
	
	#Which peer to dial
	if ($ARGV[2] eq ""){
		exit 0;
	}
	if (($ARGV[2] eq "peer") && ($ARGV[3] ne "")) {
		hangPeers($ARGV[3]);
	}
}

exit 0;

#--------------------#
# --- QUERY SUBS --- #
#--------------------#

sub qrySystem {
	foreach my $systems ($root->children('system')){
		print $systems->field('hostname') . "\n";
	}
	exit 0;
}

sub qryETH {
	foreach my $ethernet ($root->children('ethernet')){
		$eth_ipaddr = $ethernet->first_child_text('ipaddress');
		$eth_subnet = $ethernet->first_child_text('subnet');
		$eth_bitmask = getbitmask($eth_subnet);
		$eth_mtu = $ethernet->first_child_text('mtu');
		
	  print $eth_ipaddr . ",";
	  print $eth_subnet . ",";
	  print $eth_mtu . ",";
	  print "\n";
	}
	exit 0;
}

sub qryRoutes {
	my $static_count = 0;
	my $ospf_count = 0;
		
	foreach my $route ($root->children('route')){
	  my $type = $route->att('type');
	  my $network = $route->field('network');
	  my $subnet = $route->field('subnet');
    my $gw;
    my $area;
	  
	  if ($ARGV[3] eq $type){
			if ($type eq "static") {
				$static_count += 1;
				print $type . ",";
				print $static_count . ",";
				print $network . ",";
				print $subnet . ",";
				$gw = $route->field('gateway');
				print $gw . ",";	
				print "\n";
			}
			if ($type eq "ospf") {
				$ospf_count += 1;
				print $type . ",";
				print $ospf_count . ",";		
				print $network . ",";
				print $subnet . ",";
				$area = $route->field('area');
				print $area . ",";	
				print "\n";
			}
		}
	}
	exit 0;
}

sub qryOSPFOpt {
	my $count = 0;
	foreach my $p ($root->children('ospf_opt')){
		my $o_peer = $p->att('peer');
		if ($o_peer eq $ARGV[3]){
			my $o_mltpoint = $p->field('ospf_network');
			my $o_auth = $p->field('ospf_auth');
			my $o_auth_key = $p->field('ospf_auth_key');
			my $o_msg_digest_id = $p->field('ospf_message_digest_key_id');
			my $o_msg_digest_key = $p->field('ospf_message_digest_key_pass');
			my $o_cost = $p->field('ospf_cost');
			my $o_dead_int = $p->field('ospf_dead_interval');
			my $o_hello_int = $p->field('ospf_hello_interval');
			my $o_retrans_int = $p->field('ospf_retransmit_interval');
			my $o_trans_delay = $p->field('ospf_trasmit_delay');
			my $o_mtu_ignore = $p->field('ospf_mtu_ignore');
			
			print $o_peer . ",";
			print $o_mltpoint . ",";
			print $o_auth . ",";
			print $o_auth_key . ",";
			print $o_msg_digest_id . ",";
			print $o_msg_digest_key . ",";
			print $o_cost . ",";
			print $o_dead_int . ",";
			print $o_hello_int . ",";
			print $o_retrans_int . ",";
			print $o_trans_delay . ",";
			print $o_mtu_ignore;
			print "\n";
		}
	}
	exit 0;
}


sub qryPeers {
	my $count = 1;
	foreach my $peer ($root->children('peer')){
			my $peer_name = $peer->first_child_text('name');
			my $peer_localip = $peer->first_child_text('localip');
			my $peer_remoteip = $peer->first_child_text('remoteip');
			#my $peer_netmask = $peer->first_child_text('netmask');
			my $peer_netmask = "255.255.255.0";
			my $peer_number = $peer->first_child_text('number');
			my $peer_username = $peer->first_child_text('username');
			my $peer_password = $peer->first_child_text('password');
			my $peer_mtu = $peer->first_child_text('mtu');
			my $peer_mru = $peer->first_child_text('mru');
			my $peer_holdoff = $peer->first_child_text('holdoff');
			my $peer_dialmax = $peer->first_child_text('dialmax');
			my $peer_auth = $peer->first_child_text('auth');
			
			
	    print $count . ",";
	    print $peer_name . ",";
	    print $peer_localip . ",";
	    print $peer_remoteip . ",";
	    print $peer_netmask . ",";
	    print $peer_number . ",";
			print $peer_auth . ",";
    	print $peer_username . ",";
    	print $peer_password . ",";
	    print $peer_mtu . ",";
	    print $peer_mru . ",";
	    if (($peer->children_count('persist') == 1)&&($peer->field('persist') eq "1")){
		    print "1,";
	    }	
	    else {
	    	print "0,";
	    }
	    print $peer_holdoff . ",";
	    print $peer_dialmax . ",";
	
	   	my $x=1;
	   	my $elt = $peer;
	   	my @chans;
	  	while( $elt = $elt->next_elt($peer, 'chan'))
	    { 
	    	$chans[$x] = $elt->text +1 -1;
	    	$x++;
	    }
	    my $y=0;
			for ($x=1;$x<9;$x++){
				my $match = 0;
				for ($y=1;$y<9;$y++){
	    		if ($x eq $chans[$y]){
	    			$match =1;
	    		}
	    	}
	    	print $match .",";
	    }
	    print "\n";
			$count++;
	}
}


#-------------------------#
#--- Start up Routines ---#
#-------------------------#
sub doSystem {
	foreach my $systems ($root->children('system')){
		if ($action eq "startup") {
			print "Hostname: " . $systems->field('hostname') . "\n";
			print "\n";
		}
		open(FH, "> ". $debug_filename . "/etc/HOSTNAME");
		print FH $systems->field('hostname') . "\n";
		close FH; 
	}
}

sub doETH {
	foreach my $ethernet ($root->children('ethernet')){
		$eth_ipaddr = $ethernet->first_child_text('ipaddress');
		$eth_subnet = $ethernet->first_child_text('subnet');
		$eth_bitmask = getbitmask($eth_subnet);
		$eth_mtu = $ethernet->first_child_text('mtu');
		
		if ($action eq "startup") {
			print "Ethernet:\n";
		  print " interface: eth0\n";
		  print " IP address: " . $eth_ipaddr . "\n";
		  print " Subnet: " . $eth_subnet . " Bitmask: /" . $eth_bitmask . "\n";
		  print " MTU: " . $eth_mtu . "\n";
		  print "\n";
		}
		system "/sbin/ifconfig eth0 down";
		system "/sbin/ifconfig eth0 $eth_ipaddr netmask $eth_subnet mtu $eth_mtu";
		system "/sbin/ifconfig eth0 up";

	}
}

sub doRoutes {
	my $count = 0;
	my $static_routes = "";
	my $ospf_routes = "";
	my $ospf_count = 0;
	foreach my $route ($root->children('route')){
	  $count += 1;
	  my $type = $route->att('type');
	  my $network = $route->field('network');
	  my $subnet = $route->field('subnet');
	  my $bitmask = getbitmask($subnet);
    my $gw = $route->field('gateway');
    my $area = $route->field('area');
	  
		if ($action eq "startup") {
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
		
			if ($route->children_count('gateway') == 1){
				print "  gateway: " . $gw . "\n";
			}
			if ($route->children_count('area') == 1){
				print "  area: " . $area . "\n";
			}
			print "\n";
		}
		
		if ($type eq "static") {
			$static_routes = $static_routes . "ip route " . $network . "/" . $bitmask . " $gw\n";
		}
		if ($type eq "ospf") {
			$ospf_routes = $ospf_routes . "  network " . $network . "/" . $bitmask . " area $area\n";
			$ospf_count++;
		}
	}
	
	if (1){
		open(FH, "> ". $debug_filename . "/etc/routing/zebra.conf");
		print FH "! -*- zebra -*-\n\n";
		print FH "password molybdenum\n\n";
		print FH "interface eth0\n";
		print FH "  ip address " . $eth_ipaddr . "/" . $eth_bitmask . "\n\n";
		print FH "  link-detect\n";
		print FH "interface ppp1\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH "interface ppp2\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH "interface ppp3\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH "interface ppp4\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH "interface ppp5\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH "interface ppp6\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH "interface ppp7\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n";
		print FH "interface ppp8\n";
		print FH "  link-detect\n";
    print FH "  bandwidth 64\n\n";
		print FH $static_routes . "\n";
		print FH "log file /ftp/router.log\n\n";
		close FH;
	}
	if (1){
		open(FH, "> ". $debug_filename . "/etc/routing/ospfd.conf");
		print FH "! -*- OSPF -*-\n\n";
		print FH "password molybdenum\n\n";
		print FH "interface eth0\n\n";
		close FH;
		doOSPFOpt();		
		open(FH, ">> ". $debug_filename . "/etc/routing/ospfd.conf");
		print FH "router ospf\n";
		print FH $ospf_routes . "\n";
		print FH "log file /ftp/router.log\n\n";
		close FH;
	}
	my $junk_cmd = "/bin/killall zebra >> /dev/null 2>&1";
	system $junk_cmd;
	system "/bin/rm -f /var/run/zebra.pid >> /dev/null 2>&1";

	my $junk_cmd = "/bin/killall ospfd >> /dev/null 2>&1";
	system $junk_cmd;
	system "/bin/rm -f /var/run/ospfd.pid >> /dev/null 2>&1";

	system "/usr/local/sbin/zebra -d -f /etc/routing/zebra.conf";

	if ($ospf_count > 0){	system "/usr/local/sbin/ospfd -d -f /etc/routing/ospfd.conf";}

}

sub doOSPFOpt {
	my $count = 1;
	my $last_peer = 0;

	foreach my $p ($root->children('ospf_opt')){
		my $o_peer = 0;
		my $o_mltpoint = 0;
		my $o_auth = 0;
		my $o_auth_key = 0;
		my $o_msg_digest_id = 0;
		my $o_msg_digest_key = "";
		my $o_cost = 0;
		my $o_dead_int = 0;
		my $o_hello_int = 0;
		my $o_retrans_int = 0;
		my $o_trans_delay = 0;
		my $o_mtu_ignore = 0;

		$o_peer = $p->att('peer')+1-1;
		for($count=$last_peer+1;(($count<$o_peer)&&($count<9));$count++){
			open(FH, ">> ". $debug_filename . "/etc/routing/ospfd.conf");
			print FH "interface ppp". $count ."\n\n";
			close FH;
		}

		if ($p->children_count('ospf_network') >0){ $o_mltpoint = 1; } 
		if ($p->children_count('ospf_auth') > 0){ $o_auth = $p->field('ospf_auth')+1-1; }
		if ($p->children_count('ospf_auth_key') >0){ $o_auth_key = $p->field('ospf_auth_key'); }
		if ($p->children_count('ospf_message_digest_key_id') > 0){ $o_msg_digest_id = $p->field('ospf_message_digest_key_id')+1-1; }
		if ($p->children_count('ospf_message_digest_key_pass') > 0){ $o_msg_digest_key = $p->field('ospf_message_digest_key_pass'); }
		if ($p->children_count('ospf_cost') > 0){ $o_cost = $p->field('ospf_cost')+1-1; }
		if ($p->children_count('ospf_dead_interval') > 0){ $o_dead_int = $p->field('ospf_dead_interval')+1-1; }
		if ($p->children_count('ospf_hello_interval') > 0){ $o_hello_int = $p->field('ospf_hello_interval')+1-1; }
		if ($p->children_count('ospf_retransmit_interval') > 0){ $o_retrans_int = $p->field('ospf_retransmit_interval')+1-1; }
		if ($p->children_count('ospf_trasmit_delay') > 0){ $o_trans_delay = $p->field('ospf_trasmit_delay')+1-1; }
		if ($p->children_count('ospf_mtu_ignore') > 0){ $o_mtu_ignore = $p->field('ospf_mtu_ignore')+1-1; }
			
		open(FH, ">> ". $debug_filename . "/etc/routing/ospfd.conf");
		print FH "interface ppp". $o_peer ."\n";
		if ($o_mltpoint == 1) {print FH "  ip ospf network point-to-multipoint\n";}
		if ($o_auth == 1) {
			print FH "  ip ospf authentication\n";
			print FH "  ip ospf authentication-key ". $o_auth_key . "\n";
		}
		if ($o_auth == 2) {
			print FH "  ip ospf authentication null\n";
		}
		if ($o_auth == 3) {
			print FH "  ip ospf authentication message-digest\n";			
			print FH "  ip ospf message-digest-key ". $o_msg_digest_id . " md5 ". $o_msg_digest_key ."\n";
		}
		if (($o_cost > 0) && ($o_cost < 65535)) { print FH "  ip ospf cost ". $o_cost . "\n"; }
		if (($o_dead_int > 0) && ($o_dead_int < 65535)) { print FH "  ip ospf dead-interval ". $o_dead_int . "\n"; }
		if (($o_hello_int > 0) && ($o_hello_int < 65535)) { print FH "  ip ospf hello-interval ". $o_hello_int . "\n"; }
		if (($o_retrans_int > 0) && ($o_retrans_int < 65535)) { print FH "  ip ospf retransmit-interval ". $o_retrans_int . "\n"; }
		if (($o_trans_delay > 0) && ($o_trans_delay < 65535)) { print FH "  ip ospf transmit-delay ". $o_trans_delay . "\n"; }
		if ($o_mtu_ignore == 1){ 
			print FH "  ip ospf mtu-ignore\n";
		}
		print FH "\n";
		close FH;
		$last_peer = $o_peer;
	}
	for($count=$last_peer+1;$count<9;$count++){
		open(FH, ">> ". $debug_filename . "/etc/routing/ospfd.conf");
		print FH "interface ppp". $count ."\n\n";
		close FH;
	}
}

sub doPeers {
	my $count = 0;
	foreach my $peer ($root->children('peer')){
			$count += 1;
			my $peer_count = $peer->att('peer');
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
			
			
			if ($action eq "startup") {
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
		  }
	    if (($peer->children_count('persist') == 1) && ($peer->field('persist') eq "1")){
				$peer_persistent = "persist";
	   		if ($action eq "startup") { print "yes\n"; }
	    }	
	    else {
	    	if ($action eq "startup") { print "no\n"; }
	    }
	    if ($action eq "startup") { print " holdoff: " . $peer_holdoff . "\n";}
	
	   	my $elt= $peer;
	   	if ($action eq "startup") { print " chan: "; }
	  	while( $elt= $elt->next_elt($peer, 'chan'))
	    { 
	    	my $p = $elt->text;
		    if ($action eq "startup") { print $p . " ";}
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
	    if ($action eq "startup") { print "\n\n";}
	}
}

sub dialPeers {
	my $p_dial = @_;
	foreach my $peer ($root->children('peer')){
		if ($peer->att('num')==$p_dial){
			my $elt= $peer;
	  	while( $elt= $elt->next_elt($peer, 'chan'))
	    {
	    	system "kill -9 `ps aux | grep pppd | grep isdn/bch". $elt->text ." | awk '{print $2}'` >> /dev/null 2>&1";
    		system "/usr/sbin/pppd call isdn/bch". $elt->text ." >> /dev/null 2>&1";
	    }
	  }
	}
}

sub hangPeer {
	my $p_dial = @_;
	foreach my $peer ($root->children('peer')){
		if ($peer->att('num')==$p_dial){
			my $elt= $peer;
	  	while( $elt= $elt->next_elt($peer, 'chan'))
	    {
	    	system "kill -9 `ps aux | grep pppd | grep isdn/bch". $elt->text ." | awk '{print $2}'` >> /dev/null 2>&1";
	    }
	  }
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