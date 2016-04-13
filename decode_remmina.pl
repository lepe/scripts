#!/usr/bin/perl -w
# author: A.Lepe
# created: 2016-04-04
# Install (eg. using cpan): 
#    Crypt::CBC, Crypt::DES_EDE3, MIME::Base64, File::Slurp

use strict;
use warnings;
use Crypt::CBC; 
use MIME::Base64;
use File::Slurp;

my $remmina_dir = $ENV{"HOME"} . "/.remmina";
my $remmina_cfg = $remmina_dir . "/remmina.pref";

my $content = read_file($remmina_cfg);
if($content) {
    my ($secret) = $content =~ /^secret=(.*)/m;
    if($secret) {
        my $secret_bin = decode_base64($secret);
        my ($key, $iv) = ( $secret_bin =~ /.{0,24}/gs );
        my @files = <$remmina_dir/*.remmina>;
        
        my $des = Crypt::CBC->new( 
                -cipher=>'DES_EDE3', 
                -key=>$key, 
                -iv=>$iv,
                -header=>'none', 
                -literal_key=>1,
                -padding=>'null'
        ); 
        if(@files > 0) {
            foreach my $file (@files) {
                my $config = read_file($file);
                my ($password) = $config =~ /^password=(.*)/m;
                my ($name) = $config =~ /^name=(.*)/m;
                my ($host) = $config =~ /^server=(.*)/m;
                my ($user) = $config =~ /^username=(.*)/m;
                my $pass_bin = decode_base64($password);
                my $pass_plain = $des->decrypt( $pass_bin );
                if($pass_plain) {
                    print "$name    $host   $user   $pass_plain\n";
                }
            }
        } else {
            print "Unable to find *.remmina files \n";
        }
    } else {
        print "No secret key found...\n";
    }
} else {
    print "Unable to read content from remmina.pref\n";
}
