#!/usr/bin/perl -w
# @author: A.Lepe
# @since: 2015-09-04
# run: apt --installed list in each computer
# name them: compare_one.lst and compare_two.lst

use strict;
use warnings;

my $num_args = $#ARGV + 1;
my $file_one="compare_one.lst";
my $file_two="compare_two.lst";
if($num_args > 2) {
	print "Maximum 2 files to compare.\n";
	exit;
} elsif($num_args == 2) {
	$file_one=$ARGV[0];	
	$file_two=$ARGV[1];
} elsif ($num_args == 1) {
	$file_one=$ARGV[0];	
} 
if ( ! -e $file_one ) {
	print  "$file_one does not exists\n";
	print  "run: '/usr/bin/apt --installed list | tail -n+2 > compare.lst' in each computer\n";
	print  "and name them: compare_one.lst and compare_two.lst\n";
	print  "or specify two parameters to this command. For example:\n";
	print  "./compare_ubuntu_apt.pl that_server.lst this_server.lst\n";
	print  "If the second file is missing, it will automatically generated.\n";
	exit;
}
if ( ! -e $file_two ) {
	print "$file_two does not exists, assuming THIS computer\n";
	`/usr/bin/apt --installed list | tail -n+2 > $file_two`
}

open my $info1, $file_one or die "Could not open $file_one: $!";
open my $info2, $file_two or die "Could not open $file_two: $!";

my (%origin, %different, %missing);

while( my $line1 = <$info1>)  { 
	my ($pkg, $unused, $version) = split(/\/| /, $line1);
	$origin{$pkg} = $version;
}
while( my $line2 = <$info2>)  {   
	my ($pkg, $unused, $version) = split(/\/| /, $line2);
    if ( $origin{$pkg} ) {
		if( $origin{$pkg} eq $version ) {
			#Do nothing here...
		} else {
			$different{$pkg} = $origin{$pkg} . " -> " . $version;
		}
		delete ( $origin{$pkg} );
	} else {
	    $missing{$pkg} = $version;
	}
}
close $info1;
close $info2;

if (scalar(keys(%different)) > 0) {
	print "----------------------------------\n";
	print " DIFFERENCES \n";
	print "----------------------------------\n";
	foreach (sort keys %different) {
		print " @ $_ : $different{$_}\n";
	}
}
if (scalar(keys(%origin)) > 0) {
	print "----------------------------------\n";
	print " MISSING IN $file_one\n";
	print "----------------------------------\n";
	foreach (sort keys %origin) {
		print " + $_ : $origin{$_}\n";
	}
}
if (scalar(keys(%missing)) > 0) {
	print "----------------------------------\n";
	print " MISSING IN $file_two\n";
	print "----------------------------------\n";
	foreach (sort keys %missing) {
		print " - $_ : $missing{$_}\n";
	}
}
if (scalar(keys(%different)) == 0 && scalar(keys(%origin)) == 0 && scalar(keys(%missing)) == 0) {
	print "No differences were found.\n";
}
print "\n";
