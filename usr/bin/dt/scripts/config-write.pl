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
	doEthernet();
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

	system `/bin/echo $new_hostname > /etc/HOSTNAME`;
}

sub doEthernet {
	my @byline = $value;
	my @byvar = split(/,/, $byline[0]);
	my $eth_iface = $byvar[0];
	my $eth_ip = $byvar[1];
	my $eth_subnet = $byvar[2];
	my $eth_mtu = $byvar[3];
	
	
	foreach my $eth ($root->children('ethernet')){
		my $ele;

		$eth->del_att('iface');
		$eth->set_att('iface', $eth_iface);

		$eth->cut_children;

		$ele = new XML::Twig::Elt('ipaddress', $eth_ip);
		$ele->paste('last_child', $eth);

		$ele = new XML::Twig::Elt('subnet', $eth_subnet);
		$ele->paste('last_child', $eth);

		$ele = new XML::Twig::Elt('mtu', $eth_mtu);
		$ele->paste('last_child', $eth);
	}
	#change IP through zebra
	#system `/sbin/ifconfig $new_hostname > /etc/HOSTNAME`;
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

sub doPeer {
	my $ele;
	my @args = @_;
	my $value = $args[0];
	my $action = $args[1];
	if (($value eq "") || ($action eq "")) { exit 0; }
	my @val = split(/,/, $args[0]);
	my ($p, $p_count, $p_name, $p_localip, $p_remoteip, $p_netmask, $p_number, $p_auth, $p_username, $p_password );
	my ($p_mtu, $p_mru, $p_persist, $p_holdoff, $p_dialmax, @p_chan);
	my $p_matched = 0;
	
	#print "value = $value\n";
	
	#modify a peer
	if ($action eq "mod") {
		$p_count = $val[0]+1-1;
		my $count=1;
		#select existing element
		foreach my $p ($root->children('peer')){
			$p->set_att('num', $count);
			if ($p_count == $count){
				$p_matched=1;
				$p->cut_children;
				
				$p_name = $val[1];
				$ele = new XML::Twig::Elt('name', $p_name);
				$ele->paste('last_child', $p);
		
				$p_localip = $val[2];
				$ele = new XML::Twig::Elt('localip', $p_localip);
				$ele->paste('last_child', $p);
		
				$p_remoteip = $val[3];
				$ele = new XML::Twig::Elt('remoteip', $p_remoteip);
				$ele->paste('last_child', $p);
		
				$p_netmask = $val[4];
				$ele = new XML::Twig::Elt('netmask', $p_netmask);
				$ele->paste('last_child', $p);
		
				$p_number = $val[5];
				$ele = new XML::Twig::Elt('number', $p_number);
				$ele->paste('last_child', $p);
		
				$p_auth = $val[6];
				$ele = new XML::Twig::Elt('auth', $p_auth);
				$ele->paste('last_child', $p);
		
				$p_username = $val[7];
				$ele = new XML::Twig::Elt('username', $p_username);
				$ele->paste('last_child', $p);
		
				$p_password = $val[8];
				$ele = new XML::Twig::Elt('password', $p_password);
				$ele->paste('last_child', $p);
		
				$p_mtu = $val[9];
				$ele = new XML::Twig::Elt('mtu', $p_mtu);
				$ele->paste('last_child', $p);
		
				$p_mru = $val[10];
				$ele = new XML::Twig::Elt('mru', $p_mru);
				$ele->paste('last_child', $p);
		
				$p_persist = $val[11];
				$ele = new XML::Twig::Elt('persist', $p_persist);
				$ele->paste('last_child', $p);
		
				$p_holdoff = $val[12];
				$ele = new XML::Twig::Elt('holdoff', $p_holdoff);
				$ele->paste('last_child', $p);
		
				$p_dialmax = $val[13];
				$ele = new XML::Twig::Elt('dialmax', $p_dialmax);
				$ele->paste('last_child', $p);
		
				
				$p_chan[1] = $val[14];
				$p_chan[2] = $val[15];
				$p_chan[3] = $val[16];
				$p_chan[4] = $val[17];
				$p_chan[5] = $val[18];
				$p_chan[6] = $val[19];
				$p_chan[7] = $val[20];
				$p_chan[8] = $val[21];
		
				my $x;
				for ($x=1;$x<9;$x++){
					if ($p_chan[$x] eq "0"){
						$ele = new XML::Twig::Elt('chan', $x);
						$ele->paste('last_child', $p);
					}
				}
			}
			$count++;
		}
		if ($p_matched == 0) { $action="new"; }
	}
	
	#create a new peer
	if ($action eq "new") {
		#create new element
		$ele = XML::Twig::Elt->new('peer');
		$ele->paste('last_child', $root);
		
		#select new element
		my $p = $root->last_child('peer');
		$p_name = $val[1];
		$p->set_att('num', $p_count);
		
		$ele = new XML::Twig::Elt('name', $p_name);
		$ele->paste('last_child', $p);

		$p_localip = $val[2];
		$ele = new XML::Twig::Elt('localip', $p_localip);
		$ele->paste('last_child', $p);

		$p_remoteip = $val[3];
		$ele = new XML::Twig::Elt('remoteip', $p_remoteip);
		$ele->paste('last_child', $p);

		$p_netmask = $val[4];
		$ele = new XML::Twig::Elt('netmask', $p_netmask);
		$ele->paste('last_child', $p);

		$p_number = $val[5];
		$ele = new XML::Twig::Elt('number', $p_number);
		$ele->paste('last_child', $p);

		$p_auth = $val[6];
		$ele = new XML::Twig::Elt('auth', $p_auth);
		$ele->paste('last_child', $p);

		$p_username = $val[7];
		$ele = new XML::Twig::Elt('username', $p_username);
		$ele->paste('last_child', $p);

		$p_password = $val[8];
		$ele = new XML::Twig::Elt('password', $p_password);
		$ele->paste('last_child', $p);

		$p_mtu = $val[9];
		$ele = new XML::Twig::Elt('mtu', $p_mtu);
		$ele->paste('last_child', $p);

		$p_mru = $val[10];
		$ele = new XML::Twig::Elt('mru', $p_mru);
		$ele->paste('last_child', $p);

		$p_persist = $val[11];
		$ele = new XML::Twig::Elt('persist', $p_persist);
		$ele->paste('last_child', $p);

		$p_holdoff = $val[12];
		$ele = new XML::Twig::Elt('holdoff', $p_holdoff);
		$ele->paste('last_child', $p);

		$p_dialmax = $val[13];
		$ele = new XML::Twig::Elt('dialmax', $p_dialmax);
		$ele->paste('last_child', $p);

		
		$p_chan[1] = $val[14];
		$p_chan[2] = $val[15];
		$p_chan[3] = $val[16];
		$p_chan[4] = $val[17];
		$p_chan[5] = $val[18];
		$p_chan[6] = $val[19];
		$p_chan[7] = $val[20];
		$p_chan[8] = $val[21];

		my $x;
		for ($x=1;$x<9;$x++){
			if ($p_chan[$x] eq "0"){
				$ele = new XML::Twig::Elt('chan', $x);
				$ele->paste('last_child', $p);
			}
		}
	}
	
	#delete peer
	if ($action eq "del"){
		$p_count = $val[0]+1-1;
		my $count=1;
		#select new element
		foreach my $p ($root->children('peer')){
			if ($p_count == $count){
				$p->cut_children;
				$p->DESTROY;
				$p->delete;
			}
			$count++;
		}
	}
	system "/usr/bin/perl /usr/bin/dt/scripts/config-read.pl write run peers";
}


exit 0;

