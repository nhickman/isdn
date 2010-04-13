#! /usr/bin/perl -W
# Saves the config.
# Returns html if config is different.
#
use strict;

package CheckConfig;

sub Check {
	my (@a, $ret);
	my $tmp_file_name = "/ftp/.cfgdiff";
	if (-e $tmp_file_name){
		$ret =
		"<div id='cfgDiv'><form name='cfgdiff' action='save.pl' method='POST' class='cfgdiff'>NOTICE: Running config is different from startup config.".
		"<input type='submit' value='Save' name='save' class='save'></form></div>";
	}
	return $ret;
}
1;