#!/usr/bin/perl -w
# Writes configs during runtime.


use XML::Twig;
use strict;

my $args = $#ARGV + 1;

my $eth_ipaddr;
my $eth_subnet;
my $eth_bitmask;
my $eth_mtu;
#my $debug_filename = "";
my $debug_filename = "";
my $in_file = "/ftp/config-run.xml";
my $out_file = "/ftp/.cfgdiff";


##
## Args
##	0 - What are we doing: write
##  1 - Write what?: sys, eth, route, peer
##  2 - With what value?: <string>
##  3 - New or delete?: new, del
##
if ($args < 3) {
	exit 0;
}
my ($cmd, $area, $value, $action)=@ARGV;
my $twig= new XML::Twig;
$twig->parsefile($in_file);
my $root = $twig->root;
	
if (($cmd eq "write") && ($area eq "sys")){ 
	open FH, '>', $out_file or die;
	doSystem();
	$twig->flush(\*FH, pretty_print => 'indented');
	close FH;
	system `/bin/cp /ftp/.cfgdiff /ftp/config-run.xml`;
}

if (($cmd eq "write") && ($area eq "eth")){ 
	open FH, '>', $out_file or die;
	doEthernet($value, $action);
	$twig->flush(\*FH, pretty_print => 'indented');
	close FH;
	system `/bin/cp /ftp/.cfgdiff /ftp/config-run.xml`;
}

if (($cmd eq "write") && ($area eq "route")){ 
	open FH, '>', $out_file or die;
	doRoute($value, $action);
	$twig->flush(\*FH, pretty_print => 'indented');
	close FH;
	system `/bin/cp /ftp/.cfgdiff /ftp/config-run.xml`;
}

if (($cmd eq "write") && ($area eq "ospfopts")){ 
	open FH, '>', $out_file or die;
	doOSPFOpts($value, $action);
	$twig->flush(\*FH, pretty_print => 'indented');
	close FH;
	system `/bin/cp /ftp/.cfgdiff /ftp/config-run.xml`;
}

if (($cmd eq "write") && ($area eq "peer")){ 
	open FH, '>', $out_file or die;
	doPeer($value, $action);
	$twig->flush(\*FH, pretty_print => 'indented');
	close FH;
	system `/bin/cp /ftp/.cfgdiff /ftp/config-run.xml`;
}

exit 0;

sub doSystem {
	my $new_hostname = chomp($value);
	foreach my $systems ($root->children('system')){
		$systems->cut_children;
		my $ele = new XML::Twig::Elt('hostname', $value);
		$ele->paste('last_child', $systems);
	}

	system "/bin/echo $new_hostname > /etc/HOSTNAME";
}

sub doEthernet {
	my @args = @_;
	my $value = $args[0];
	my $actio = $args[1];
	my @val = split(/,/, $value);
	if (($value eq "") || ($action eq "")) { exit 0; }
	my $eth_iface = $val[0];
	my $eth_ip = $val[1];
	my $eth_subnet = $val[2];
	my $eth_mtu = $val[3];
	
	if ($action eq "mod") {
		foreach my $eth ($root->children('ethernet')){
			my $ele;
			$eth->cut_children;

			$ele = new XML::Twig::Elt('ipaddress', $eth_ip);
			$ele->paste('last_child', $eth);

			$ele = new XML::Twig::Elt('subnet', $eth_subnet);
			$ele->paste('last_child', $eth);

			$ele = new XML::Twig::Elt('mtu', $eth_mtu);
			$ele->paste('last_child', $eth);
		}
		#change IP through zebra
		system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl write run eth";
	}
}

sub doRoute {
	my $ele;
	my @args = @_;
	my $value = $args[0];
	my $action = $args[1];
	if (($value eq "") || ($action eq "")) { exit 0; }
	my @val = split(/,/, $args[0]);
	my $route_type = $val[0];
	my $route_count = $val[1];
	my $route_net = $val[2];
	my $route_subnet = $val[3];
	my $route_gw = 0;
	my $route_area = 0;
	if ($route_type eq "static"){ $route_gw = $val[4]; }
	if ($route_type eq "ospf"){ $route_area = $val[4]; }
	
	#create a new route
	if ($action eq "new") {		
		#create new element
		my $test = $root->last_child;
		$ele = XML::Twig::Elt->new('route');
		$ele->paste('last_child', $root);
		
		#select new element
		my $route = $root->last_child('route');
		$route->set_att('type', $route_type);
		$ele = new XML::Twig::Elt('network', $route_net);
		$ele->paste('last_child', $route);
		
		$ele = new XML::Twig::Elt('subnet', $route_subnet);
		$ele->paste('last_child', $route);

		if ($route_type eq "static"){
			$ele = new XML::Twig::Elt('gateway', $route_gw);
			$ele->paste('last_child', $route);
		}

		if ($route_type eq "ospf"){
			$ele = new XML::Twig::Elt('area', $route_area);
			$ele->paste('last_child', $route);
		}
	}
	
	#modify existing route
	if ($action eq "mod"){
		my $count=1;
		#select new element
		foreach my $route ($root->children('route')){
			if ($route->att('type') eq $route_type) {
				if ($route_count == $count){
					$route->cut_children;
	
					$ele = new XML::Twig::Elt('network', $route_net);
					$ele->paste('last_child', $route);
				
					$ele = new XML::Twig::Elt('subnet', $route_subnet);
					$ele->paste('last_child', $route);
		
					if ($route_type eq "static"){
						$ele = new XML::Twig::Elt('gateway', $route_gw);
						$ele->paste('last_child', $route);
					}
		
					if ($route_type eq "ospf"){
						$ele = new XML::Twig::Elt('area', $route_area);
						$ele->paste('last_child', $route);
					}
				}
				$count++;
			}
		}
	}		
	
	#delete route
	if ($action eq "del"){
		my $count=1;
		#select new element
		foreach my $route ($root->children('route')){
			if ($route->att('type') eq $route_type) {
				if ($route_count == $count){
					$route->cut_children;
					$route->DESTROY;
					$route->delete;
				}
				$count++;
			}
		}
	}
	system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl write run route";
}

sub doOSPFOpts {
	my $ele;
	my @args = @_;
	my $value = $args[0];
	print "value = $value";
	my $action = $args[1];
	if (($value eq "") || ($action eq "")) { exit 0; }
	my @val = split(/,/, $args[0]);
	my $opt_peer = 						$val[0];
	my $opt_network = 				$val[1];
	my $opt_auth = 						$val[2];
	my $opt_auth_key = 				$val[3];
	my $opt_msg_digest_id = 	$val[4];
	my $opt_msg_digest_key = 	$val[5];
  my $opt_cost = 						$val[6];
  my $opt_dead_int = 				$val[7];
  my $opt_hello_int = 			$val[8];
  my $opt_retrans_int = 		$val[9];
  my $opt_trans_delay = 		$val[10];
  my $opt_mtu_ignore = 			$val[11];
  my $opt_priority = 				$val[12];
  my $opt_matched = 0;
  	

	#modify existing route
	if ($action eq "mod"){
		#select new element
		foreach my $opt ($root->children('ospf_opt')){
			if ($opt->att('peer') eq $opt_peer) {
				$opt_matched=1;
				
				$opt->set_att('peer', $opt_peer);
				
				$opt->cut_children;
	
				$ele = new XML::Twig::Elt('ospf_network', $opt_network);
				$ele->paste('last_child', $opt);
		
				$ele = new XML::Twig::Elt('ospf_auth', $opt_auth);
				$ele->paste('last_child', $opt);
		
				$ele = new XML::Twig::Elt('ospf_auth_key', $opt_auth_key);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_message_digest_key_id', $opt_msg_digest_id);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_message_digest_key_pass', $opt_msg_digest_key);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_cost', $opt_cost);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_dead_interval', $opt_dead_int);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_hello_interval', $opt_hello_int);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_retransmit_interval', $opt_retrans_int);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_trasmit_delay', $opt_trans_delay);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('ospf_mtu_ignore', $opt_mtu_ignore);
				$ele->paste('last_child', $opt);
				
				$ele = new XML::Twig::Elt('opt_priority', $opt_priority);
				$ele->paste('last_child', $opt);
			}
		}
		if ($opt_matched == 0) {$action = "new";}
	}

	#create a new route
	if ($action eq "new") {		
		#create new element
		$ele = XML::Twig::Elt->new('ospf_opt');
		$ele->paste('last_child', $root);

		#select new element
		my $opt = $root->last_child('ospf_opt');
		$opt->set_att('peer', $opt_peer);
		
		$ele = new XML::Twig::Elt('ospf_network', $opt_network);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_auth', $opt_auth);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_auth_key', $opt_auth_key);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_message_digest_key_id', $opt_msg_digest_id);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_message_digest_key_pass', $opt_msg_digest_key);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_cost', $opt_cost);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_dead_interval', $opt_dead_int);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_hello_interval', $opt_hello_int);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_retransmit_interval', $opt_retrans_int);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_trasmit_delay', $opt_trans_delay);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('ospf_mtu_ignore', $opt_mtu_ignore);
		$ele->paste('last_child', $opt);
		
		$ele = new XML::Twig::Elt('opt_priority', $opt_priority);
		$ele->paste('last_child', $opt);
	}
	
	system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl write run route";
}

sub doPeer {
	my $ele;
	my @args = @_;
	my $value = $args[0];
	my $action = $args[1];
	if (($value eq "") || ($action eq "")) { exit 0; }
	my @val = split(/,/, $args[0]);
	my $p;
	my $p2;
	my $p_matched = 0;
	my $x;
	
	#modify a peer
	if ($action eq "mod") {
		#find the existing element
		foreach my $p ($root->children('peer')){
			if ($p->att('num') eq $val[0]){
				$p_matched=1;
				$p2 = $p;
				$p->del_att('num');
				$p->cut_children;
			}
		}
		if ($p_matched == 0) {$action = 'new';}
	}
	#peer not found
	if ($action eq "new") {
		#create new element
		$ele = XML::Twig::Elt->new('peer');
		$ele->paste('last_child', $root);

		#select new element
		$p2 = $root->last_child('peer');
		$p_matched = 1;
	}
	if ($p_matched == 1){
		#set to matched peer or new entry
		$p = $p2;
		
		#set peer entry number
		$p->set_att('num', $val[0]);

		$ele = new XML::Twig::Elt('name', $val[1]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('localip', $val[2]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('remoteip', $val[3]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('netmask', $val[4]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('number', $val[5]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('auth', $val[6]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('username', $val[7]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('password', $val[8]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('mtu', $val[9]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('mru', $val[10]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('persist', $val[11]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('holdoff', $val[12]);
		$ele->paste('last_child', $p);

		$ele = new XML::Twig::Elt('dialmax', $val[13]);
		$ele->paste('last_child', $p);

		for ($x=14;$x<=21;$x++){
			if ($val[$x] eq "1"){
				$ele = new XML::Twig::Elt('chan', $x - 13);
				$ele->paste('last_child', $p);
			}
		}
	}
	system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl write run peers";
}


exit 0;

