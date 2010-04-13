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
	@ro @ro_entry @ro_def @ro_type @ro_net @ro_mask @ro_gw @ro_pri @ro_iface @ro_html $ro_html $ro_num
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
					$ro_html
					<h2 class='sh2'>BGP Networks</h2>
					$rb_html
					<h2 class='sh2'>RIP Networks</h2>
					$rr_html
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
	line = $line<br>
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
	my(@run, $doRoute, @lvars, $i, $j, $net, $mask, $gw);
	$ok = 0;

	if (($vardata[0] > 0 && $vardata[0] < 100) &&
			($vardata[1] >= 0 && $vardata[1] <= 255) &&
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
			($vardata[12] >= 0 && $vardata[12] <= 255))
	{
		$j=0;
		$net 	= $vardata[1].".".$vardata[2].".".$vardata[3].".".$vardata[4];
		$mask 	= $vardata[5].".".$vardata[6].".".$vardata[7].".".$vardata[8];
		$gw 	= $vardata[9].".".$vardata[10].".".$vardata[11].".".$vardata[12];
		$rs_num++;
		$doRoute = 8195 . " " . $vardata[0] . " "."0 static " .$net." ".$mask." ".$gw." 1";
		$ok = 1;
	}

	if ($varname[13] eq "sdelete"){
		$doRoute = 8196 . " " . $vardata[0];
		$ok = 1;
	}

	if ($ok == 1){
		$cmd = "/usr/bin/dt/msgsend " . $doRoute;
		@run = `$cmd`;
	}
}


sub getInfo {
	my(@a);
	$uname=`uptime`;

}


sub getSRoutes {
	#@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface
	my($i, @a1, @a2, @a3, @net, @mask, @gw, $x);
	$x = 0;
	@a1 = `/usr/bin/dt/msgsend 4100`;
	$rs_num = 0;
	foreach $i(@a1) {
		$rs[$x] = $a1[$x];
		@a2 = split(/ /,$i);
		$rs_entry[$x]	= $a2[0];
		$rs_def[$x]		= $a2[1];
		$rs_type[$x]	= $a2[2];
		$rs_net[$x]		= $a2[3];
		$rs_mask[$x]	= $a2[4];
		$rs_gw[$x]		= $a2[5];
		$rs_pri[$x]		= $a2[6];
		@net 	= split(/\./, $rs_net[$x]);
		@mask 	= split(/\./, $rs_mask[$x]);
		@gw 	= split(/\./, $rs_gw[$x]);

		$rs_html = $rs_html .
			"<form name='routing' action='routing.pl' method='POST' class='routing'>".
			"<input type='hidden' name='entry' value=".$rs_entry[$x].">".
			"<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>".
			"Network:<input name='snet1' type='text' value='".$net[0]."' maxlength=3 style='width: 30px;' />.<input name='snet2' type='text' value='".$net[1]."' maxlength=3 style='width: 30px'/>.<input name='snet3' type='text' value='".$net[2]."' maxlength=3 style='width: 30px'/>.<input name='snet4' type='text' value='".$net[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Mask:<input name='smask1' type='text' value='".$mask[0]."' maxlength=3 style='width: 30px;' />.<input name='smask2' type='text' value='".$mask[1]."' maxlength=3 style='width: 30px'/>.<input name='smask3' type='text' value='".$mask[2]."' maxlength=3 style='width: 30px'/>.<input name='smask4' type='text' value='".$mask[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Gateway:<input name='sgw1' type='text' value='".$gw[0]."' maxlength=3 style='width: 30px;' />.<input name='sgw2' type='text' value='".$gw[1]."' maxlength=3 style='width: 30px'/>.<input name='sgw3' type='text' value='".$gw[2]."' maxlength=3 style='width: 30px'/>.<input name='sgw4' type='text' value='".$gw[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"<input type='checkbox' value='delete' name='sdelete' class='rcheck'>delete&nbsp;<input type='submit' value='Modify' name='smod' class='rbuttons'></div>".
			"</form>";

		$x++;
		$rs_num++;
	}
	if ($rs_entry[$x] < 99) {
		$rs_html = $rs_html .
			"<form name='routing' action='routing.pl' method='POST' class='routing'>".
			"<input type='hidden' name='entry' value='99'>".
			"<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>".
			"Network:<input name='snet1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='snet1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='snet1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='snet1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;".
			"Mask:<input name='smask1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='smask1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='smask1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='smask1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;".
			"Gateway:<input name='sgw1011' type='text' value='' maxlength=3 style='width: 30px;' />.<input name='sgw1012' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='sgw1013' type='text' value='' maxlength=3 style='width: 30px'/>.<input name='sgw1014' type='text' value='' maxlength=3 style='width: 30px'/>&nbsp;".
			"</div>".
			"<img src='../images/spacer.gif' width=1px height=10px>".
			"<div id='submit'><input type='submit' value='add static' name='smod' class='rbutton'></div>".
			"</form>";
	}

	$#a1 = 0;
	$#a2 = 0;
	$#a3 = 0;

}

sub getORoutes {
	#@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface
	my($i, @a1, @a2, @a3, @net, @mask, @gw, $x);
	$x = 0;
	@a1 = `/usr/bin/dt/msgsend 4101`;
	foreach $i(@a1) {
		$ro[$x] = $a1[$x];
		@a2 = split(/ /,$i);
		$ro_entry[$x]	= $a2[0];
		$ro_def[$x]		= $a2[1];
		$ro_type[$x]	= $a2[2];
		$ro_net[$x]		= $a2[3];
		$ro_mask[$x]	= $a2[4];
		$ro_gw[$x]		= $a2[5];
		$ro_pri[$x]		= $a2[6];
		$ro_iface[$x]	= $a2[7];
		@net 	= split(/\./, $ro_net[$x]);
		@mask 	= split(/\./, $ro_mask[$x]);
		@gw 	= split(/\./, $ro_gw[$x]);

		$ro_html = $ro_html . "<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>".
			"Network:<input name='onet1' type='text' value='".$net[0]."' maxlength=3 style='width: 30px;' />.<input name='onet2' type='text' value='".$net[1]."' maxlength=3 style='width: 30px'/>.<input name='onet3' type='text' value='".$net[2]."' maxlength=3 style='width: 30px'/>.<input name='onet4' type='text' value='".$net[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Mask:<input name='omask1' type='text' value='".$mask[0]."' maxlength=3 style='width: 30px;' />.<input name='omask2' type='text' value='".$mask[1]."' maxlength=3 style='width: 30px'/>.<input name='omask3' type='text' value='".$mask[2]."' maxlength=3 style='width: 30px'/>.<input name='omask4' type='text' value='".$mask[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Gateway:<input name='ogw1' type='text' value='".$gw[0]."' maxlength=3 style='width: 30px;' />.<input name='ogw2' type='text' value='".$gw[1]."' maxlength=3 style='width: 30px'/>.<input name='ogw3' type='text' value='".$gw[2]."' maxlength=3 style='width: 30px'/>.<input name='ogw4' type='text' value='".$gw[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"<input type='submit' value='-' name='odelete' class='sbuttons'></div>";

		$x++;
	}
	if ($ro_html == "" ){
		$ro_html = "To be done.";
	}
	$#a1 = 0;
	$#a2 = 0;
	$#a3 = 0;

}

sub getBRoutes {
	#@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface
	my($i, @a1, @a2, @a3, @net, @mask, @gw, $x);
	$x = 0;
	@a1 = `/usr/bin/dt/msgsend 4102`;
	foreach $i(@a1) {
		$rs[$x] = $a1[$x];
		@a2 = split(/ /,$i);
		$rb_entry[$x]	= $a2[0];
		$rb_def[$x]		= $a2[1];
		$rb_type[$x]	= $a2[2];
		$rb_net[$x]		= $a2[3];
		$rb_mask[$x]	= $a2[4];
		$rb_gw[$x]		= $a2[5];
		$rb_pri[$x]		= $a2[6];
		$rb_iface[$x]	= $a2[7];
		@net 	= split(/\./, $rb_net[$x]);
		@mask 	= split(/\./, $rb_mask[$x]);
		@gw 	= split(/\./, $rb_gw[$x]);

		$rb_html = $rb_html . "<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>".
			"Network:<input disabled name='bnet".$x."1' type='text' value='".$net[0]."' maxlength=3 style='width: 30px;' />.<input disabled name='bnet".$x."2' type='text' value='".$net[1]."' maxlength=3 style='width: 30px'/>.<input disabled name='bnet".$x."3' type='text' value='".$net[2]."' maxlength=3 style='width: 30px'/>.<input disabled name='bnet".$x."4' type='text' value='".$net[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Mask:<input disabled name='bmask".$x."1' type='text' value='".$mask[0]."' maxlength=3 style='width: 30px;' />.<input disabled name='bmask".$x."2' type='text' value='".$mask[1]."' maxlength=3 style='width: 30px'/>.<input disabled name='bmask".$x."3' type='text' value='".$mask[2]."' maxlength=3 style='width: 30px'/>.<input disabled name='bmask".$x."4' type='text' value='".$mask[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Gateway:<input disabled name='bgw".$x."1' type='text' value='".$gw[0]."' maxlength=3 style='width: 30px;' />.<input disabled name='bgw".$x."2' type='text' value='".$gw[1]."' maxlength=3 style='width: 30px'/>.<input disabled name='bgw".$x."3' type='text' value='".$gw[2]."' maxlength=3 style='width: 30px'/>.<input disabled name='bgw".$x."4' type='text' value='".$gw[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"<input type='submit' value='-' name='bdelete' class='sbuttons'></div>";

		$x++;
	}
	if ($rb_html == "" ){
		$rb_html = "To be done.";
	}

	$#a1 = 0;
	$#a2 = 0;
	$#a3 = 0;

}

sub getRRoutes {
	#@rs @rs_entry @rs_def @rs_type @rs_net @rs_mask @rs_gw @rs_pri @rs_iface
	my($i, @a1, @a2, @a3, @net, @mask, @gw, $x);
	$x = 0;
	@a1 = `/usr/bin/dt/msgsend 4103`;
	foreach $i(@a1) {
		$rs[$x] = $a1[$x];
		@a2 = split(/ /,$i);
		$rr_entry[$x]	= $a2[0];
		$rr_def[$x]		= $a2[1];
		$rr_type[$x]	= $a2[2];
		$rr_net[$x]		= $a2[3];
		$rr_mask[$x]	= $a2[4];
		$rr_gw[$x]		= $a2[5];
		$rr_pri[$x]		= $a2[6];
		$rr_iface[$x]	= $a2[7];
		@net 	= split(/\./, $rr_net[$x]);
		@mask 	= split(/\./, $rr_mask[$x]);
		@gw 	= split(/\./, $rr_gw[$x]);

		$rr_html = $rr_html . "<div id='setting'><span id='label' style='width: 50px;'>&nbsp;</span>".
			"Network:<input name='rnet".$x."1' type='text' value='".$net[0]."' maxlength=3 style='width: 30px;' />.<input name='rnet".$x."2' type='text' value='".$net[1]."' maxlength=3 style='width: 30px'/>.<input name='rnet".$x."3' type='text' value='".$net[2]."' maxlength=3 style='width: 30px'/>.<input name='rnet".$x."4' type='text' value='".$net[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Mask:<input name='rmask".$x."1' type='text' value='".$mask[0]."' maxlength=3 style='width: 30px;' />.<input name='rmask".$x."2' type='text' value='".$mask[1]."' maxlength=3 style='width: 30px'/>.<input name='rmask".$x."3' type='text' value='".$mask[2]."' maxlength=3 style='width: 30px'/>.<input name='rmask".$x."4' type='text' value='".$mask[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"Gateway:<input name='rgw".$x."1' type='text' value='".$gw[0]."' maxlength=3 style='width: 30px;' />.<input name='rgw".$x."2' type='text' value='".$gw[1]."' maxlength=3 style='width: 30px'/>.<input name='rgw".$x."3' type='text' value='".$gw[2]."' maxlength=3 style='width: 30px'/>.<input name='rgw".$x."4' type='text' value='".$gw[3]."' maxlength=3 style='width: 30px'/>&nbsp;".
			"<input type='submit' value='-' name='rdelete' class='sbuttons'></div>";

		$x++;
	}
	if ($rr_html == "" ){
		$rr_html = "To be done.";
	}

	$#a1 = 0;
	$#a2 = 0;
	$#a3 = 0;

}
