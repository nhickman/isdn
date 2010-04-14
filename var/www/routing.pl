#! /usr/bin/perl -W
# Main page for the router.  Shows a brief summary of interfaces.
#
use strict;
use warnings;
use CGI;
use CGI::Ajax;
require include::CheckConfig;

use vars qw(
	@varname @vardata $line @values $ok $cmd $cfgdiff
	$uname
	@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface @rs_html $rs_html $rs_num
	@ro @ro_entry @ro_def @ro_type @ro_net @ro_mask @ro_area @ro_pri @ro_iface @ro_html $ro_html $ro_num
	@rb @rb_entry @rb_def @rb_type @rb_net @rb_mask @rb_gw @rb_pri @rb_iface @rb_html $rb_html $rb_num
	@rr @rr_entry @rr_def @rr_type @rr_net @rr_mask @rr_gw @rr_pri @rr_iface @rr_html $rr_html $rr_num
);
getEnv();
if (@varname){
	doStuff();
}
$cfgdiff = CheckConfig::Check();
getInfo();
getSRoutes();
getORoutes();
getBRoutes();
getRRoutes();

my $cgi = CGI->new();
my $ajax = CGI::Ajax->new( 'getEnv' => \&getEnv );
print $ajax->build_html ( $cgi, \&main );

sub main {
	my $html = <<EOHTML;
	<html>
	<head>
	<style type="text/css">
		ul.tabs { list-style-type: none;
				  padding: 0;
				  margin: 0px 20px 5px;
					margin-bottom: 10px;}
		ul.tabs li { float: left;
					 padding: 1;
					 margin: 0;
					 padding-top: 0;
					 margin-right: 1px;
					 margin-bottom: 10px;
					 width: 140px;
					 color: black;
					 background-color: #BFBFBF;}
		ul.tabs li a { display:
					   block;
					   padding: 0px 10px;
					   color: black;
					   text-decoration: none;}
		ul.tabs li a:hover { background-color: black; color: white; }
	</style>
		<title>DTECH Labs - Router</title>
		<link href='../css/style.css' rel='stylesheet' type='text/css'>
	</head>
	<body>
	<center>
	<div id='wrapper'>
		<div id='header'>
			<div id='logo'>
				<img src='../images/banner100.jpg'>
			</div>
		</div>
		<div id='menuDiv'>
			<a id='menuLink' href='../'>status</a>&nbsp;
			<a id='menuLink' href='ethernet.pl'>ethernet</a>&nbsp;
			<a id='menuLink' href='isdn.pl'>ISDN</a>&nbsp;
			<a id='menuLink' href='routing.pl'>routing</a>&nbsp;
			<a id='menuLink' href='security.pl'>security</a>&nbsp;
			<a id='menuLink' href='admin.pl'>admin</a>
		</div>
		$cfgdiff
		<div id='content'>
			<h2>Routing Configuration</h2>
			<div id='colFull'>
				<fieldset style='height: 400px;'>
					<legend>Routes</legend>
					<h2 class='sh2'>Static Routes</h2>
					$rs_html
					<h2 class='sh2'>OSPF Networks</h2>
					<div id='colFull'>
							<ul class="tabs">
								<li style=""><a href='ospf_peer.pl' style="">OSPF Peer Options</a></li>
							</ul>
							<img src='../images/spacer.gif' width=1px height=5px>
							<p align='left'><i>example - Network: 192.168.1.0 Mask: 255.255.255.0 Area 0</i></p
					</div>
					$ro_html
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
	</form>
	</body>
	</html>
EOHTML

	return $html;
}


sub getEnv {
	my($i, $a);
	read(STDIN, $line, $ENV{'CONTENT_LENGTH'});
	@values = split(/&/, $line);
	$a=0;
	foreach $i(@values) {
		($varname[$a], $vardata[$a]) = split(/=/, $i);
		$vardata[$a] =~ tr/+/ /;
		$vardata[$a] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$a++;
	}
}

sub doStuff {
	$ok = 0;

	if ($vardata[0] eq "static"){
		my(@run, $doRoute, @lvars, $i, $j, $net, $mask, $gw);
		my $route = $vardata[1];
		if ($varname[14] eq "smod"){
			if (($vardata[1] > 0 && $vardata[1] < 100) &&
					($vardata[2] >= 0 && $vardata[2] <= 255) &&
					($vardata[3] >= 0 && $vardata[3] <= 255) &&
					($vardata[4] >= 0 && $vardata[4] <= 255) &&
					($vardata[5] >= 0 && $vardata[5] <= 255) &&
					($vardata[6] >= 0 && $vardata[6] <= 255) &&
					($vardata[7] >= 0 && $vardata[7] <= 255) &&
					($vardata[8] >= 0 && $vardata[8] <= 255) &&
					($vardata[9] >= 0 && $vardata[9] <= 255) &&
					($vardata[10] >= 0 && $vardata[10] <= 255) &&
					($vardata[11] >= 0 && $vardata[11] <= 255) &&
					($vardata[12] >= 0 && $vardata[12] <= 255) &&
					($vardata[13] >= 0 && $vardata[13] <= 255))
			{
				$net 	= $vardata[2].".".$vardata[3].".".$vardata[4].".".$vardata[5];
				$mask 	= $vardata[6].".".$vardata[7].".".$vardata[8].".".$vardata[9];
				$gw 	= $vardata[10].".".$vardata[11].".".$vardata[12].".".$vardata[13];
				$ok = 1;
				if ($ok == 1){
					if ($vardata[1] == 99){
						system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write route \"static,$route,$net,$mask,$gw\" new";
					}
					else {
						system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write route \"static,$route,$net,$mask,$gw\" mod";
					}
				}
			}
		}

		if ($varname[14] eq "sdelete"){
			$ok = 1;
				if ($ok == 1){
					system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write route static,$route del";
				}
		}

	}
	
	if ($vardata[0] eq "ospf"){
		my(@run, $doRoute, @lvars, $i, $j, $net, $mask, $area);
		my $route = $vardata[1];
		if ($varname[11] eq "omod"){
			if (($vardata[1] > 0 && $vardata[1] < 100) &&
					($vardata[2] >= 0 && $vardata[2] <= 255) &&
					($vardata[3] >= 0 && $vardata[3] <= 255) &&
					($vardata[4] >= 0 && $vardata[4] <= 255) &&
					($vardata[5] >= 0 && $vardata[5] <= 255) &&
					($vardata[6] >= 0 && $vardata[6] <= 255) &&
					($vardata[7] >= 0 && $vardata[7] <= 255) &&
					($vardata[8] >= 0 && $vardata[8] <= 255) &&
					($vardata[9] >= 0 && $vardata[9] <= 255) &&
					($vardata[10] >= 0))
			{
				$net 	= $vardata[2].".".$vardata[3].".".$vardata[4].".".$vardata[5];
				$mask 	= $vardata[6].".".$vardata[7].".".$vardata[8].".".$vardata[9];
				$area 	= $vardata[10];
				$rs_num++;
				$ok = 1;
				if ($ok == 1){
					if ($vardata[1] == 99){
						system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write route \"ospf,$route,$net,$mask,$area\" new";
					}
					else {
						system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write route \"ospf,$route,$net,$mask,$area\" mod";
					}
				}
			}
		}

		if ($varname[11] eq "odelete"){
			$ok = 1;
				if ($ok == 1){
					system "/usr/bin/perl /usr/bin/dt/scripts/config-write.pl write route ospf,$route del";
				}
		}
	}
}


sub getInfo {
	my(@a);
	$uname=`uptime`;

}


sub getSRoutes {
	#@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface
	my($i, @a1, @a2, @a3, @net, @mask, @gw, $x);
	$x = 1;
	@a1 = `/usr/bin/perl /usr/bin/dt/scripts/config-read.pl query run route static`;
	$rs_num = 0;
	foreach $i(@a1) {
		chomp($i);
	  if ($i ne ""){
			$rs[$x] = $a1[$x];
			@a2 = split(/,/,$i);
			$rs_entry[$x]	= $a2[1];
			$rs_type[$x]	= $a2[0];
			$rs_net[$x]		= $a2[2];
			$rs_mask[$x]	= $a2[3];
			$rs_gw[$x]		= $a2[4];
			@net 	= split(/\./, $rs_net[$x]);
			@mask 	= split(/\./, $rs_mask[$x]);
			@gw 	= split(/\./, $rs_gw[$x]);

			$rs_html = $rs_html .
				"<form name='routing' action='routing.pl' method='POST' class='routing'>\n".
				"<input type='hidden' name='type' value='static'>\n".
				"<input type='hidden' name='entry' value=".$rs_entry[$x].">\n".
				"<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>\n".
				"Network:<input name='snet1' type='text' value='".$net[0]."' maxlength=3 style='width: 30px;' />.<input name='snet2' type='text' value='".$net[1]."' maxlength=3 style='width: 30px'/>.<input name='snet3' type='text' value='".$net[2]."' maxlength=3 style='width: 30px'/>.<input name='snet4' type='text' value='".$net[3]."' maxlength=3 style='width: 30px'/>&nbsp;\n".
				"Mask:<input name='smask1' type='text' value='".$mask[0]."' maxlength=3 style='width: 30px;' />.<input name='smask2' type='text' value='".$mask[1]."' maxlength=3 style='width: 30px'/>.<input name='smask3' type='text' value='".$mask[2]."' maxlength=3 style='width: 30px'/>.<input name='smask4' type='text' value='".$mask[3]."' maxlength=3 style='width: 30px'/>&nbsp;\n".
				"Gateway:<input name='sgw1' type='text' value='".$gw[0]."' maxlength=3 style='width: 30px;' />.<input name='sgw2' type='text' value='".$gw[1]."' maxlength=3 style='width: 30px'/>.<input name='sgw3' type='text' value='".$gw[2]."' maxlength=3 style='width: 30px'/>.<input name='sgw4' type='text' value='".$gw[3]."' maxlength=3 style='width: 30px'/>&nbsp;\n".
				"<input type='checkbox' value='delete_static' name='sdelete' class='rcheck'>delete&nbsp;<input type='submit' value='Modify' name='smod' class='rbuttons'></div>\n".
				"</form>\n";

			$x++;
			$rs_num++;
		}
	}
	if ($rs_entry[$x] < 99) {
		$rs_html = $rs_html .
			"<form name='routing' action='routing.pl' method='POST' class='routing'>\n".
				"<input type='hidden' name='type' value='static'>\n".
			"<input type='hidden' name='entry' value='99'>\n".
			"<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>\n".
			"Network:<input name='snet1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='snet1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='snet1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='snet1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;\n".
			"Mask:<input name='smask1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='smask1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='smask1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='smask1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;\n".
			"Gateway:<input name='sgw1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='sgw1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='sgw1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='sgw1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;\n".
			"<input type='submit' value='add_static' name='smod' style='margin-left: 40px' class='rbuttons'></div>\n".
			"</form>\n";
	}

	$#a1 = 0;
	$#a2 = 0;
	$#a3 = 0;

}

sub getORoutes {
	#@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface
	my($i, @a1, @a2, @a3, @net, @mask, @area, $x);
	$x = 1;
	@a1 = `/usr/bin/perl /usr/bin/dt/scripts/config-read.pl query run route ospf`;
	foreach $i(@a1) {
		chomp($i);
		if ($i ne ""){
			@a2 = split(/,/,$i);
			$x = $a2[1];
			$ro_entry[$x]	= $a2[1];
			$ro_type[$x]	= $a2[0];
			$ro_net[$x]		= $a2[2];
			$ro_mask[$x]	= $a2[3];
			$ro_area[$x]	= $a2[4];
			@net 	= split(/\./, $ro_net[$x]);
			@mask 	= split(/\./, $ro_mask[$x]);
			@area 	= split(/\./, $ro_area[$x]);
	
			$ro_html = $ro_html .
					"<form name='routing' action='routing.pl' method='POST' class='routing'>\n".
					"<input type='hidden' name='type' value='ospf'>\n".
					"<input type='hidden' name='entry' value=".$ro_entry[$x].">\n".
					"<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>\n".
					"Network:<input name='onet1' type='text' value='".$net[0]."' maxlength=3 style='width: 30px;' />.<input name='onet2' type='text' value='".$net[1]."' maxlength=3 style='width: 30px'/>.<input name='onet3' type='text' value='".$net[2]."' maxlength=3 style='width: 30px'/>.<input name='onet4' type='text' value='".$net[3]."' maxlength=3 style='width: 30px'/>&nbsp;\n".
					"Mask:<input name='omask1' type='text' value='".$mask[0]."' maxlength=3 style='width: 30px;' />.<input name='omask2' type='text' value='".$mask[1]."' maxlength=3 style='width: 30px'/>.<input name='omask3' type='text' value='".$mask[2]."' maxlength=3 style='width: 30px'/>.<input name='omask4' type='text' value='".$mask[3]."' maxlength=3 style='width: 30px'/>&nbsp;\n".
					"Area:<input name='oarea1' type='text' value='".$area[0]."' maxlength=10 style='width: 60px;' />\n" .
					"<input type='checkbox' value='delete_ospf' name='odelete' class='rcheck'>delete&nbsp;<input type='submit' value='Modify' name='omod' class='rbuttons'></div>\n".
					"</form>\n";
		}
	}
	if ($rs_entry[$x] < 99) {
		$ro_html = $ro_html .
			"<form name='routing' action='routing.pl' method='POST' class='routing'>\n".
			"<input type='hidden' name='type' value='ospf'>\n".
			"<input type='hidden' name='entry' value='99'>\n".
			"<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>\n".
			"Network:<input name='onet1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='onet1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='onet1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='onet1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;\n".
			"Mask:<input name='omask1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='omask1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='omask1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='omask1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;\n".
			"Area:<input name='oarea1011' type='text' value='' maxlength=10 style='width: 60px;' />&nbsp;\n".
			"<input type='submit' value='add_ospf' name='omod' style='margin-left: 40px' class='rbuttons'></div>\n".
			"</form>\n";
	}
	$#a1 = 0;
	$#a2 = 0;
	$#a3 = 0;

}

sub getBRoutes {
}

sub getRRoutes {
}
