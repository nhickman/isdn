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
		
		$ele = new XML::Twig::Elt('subnet', $route_net);
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
				}
				$count++;
			}
		}
	}

}

