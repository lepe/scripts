#!/usr/bin/perl

use warnings;
use strict;

my ($auto_add) = @ARGV;
if(!defined $auto_add) {
	$auto_add = "";
}

my @mods = `git status --porcelain 2>/dev/null | grep '^ M ' | awk '{ print \$2 }'`;
chomp(@mods);
for my $mod (@mods) {
	my $diff = `git diff -b $mod 2>/dev/null`;
	if($diff) {
		print $mod."\n";
		if($auto_add eq "add") {
			`git add $mod 2>/dev/null`;
		}
	}
}
