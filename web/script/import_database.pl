#!/usr/bin/env perl

use strict;
use utf8;
use File::Find;

use FindBin qw($Bin);
use lib "$Bin/../lib";


my $root_src = "$Bin/../root/src/";


foreach my $base_dir (("$root_src/artigos")){

    find(sub {
        next if -d $File::Find::name;

        my $dir = "$File::Find::dir";
        my $qdir = quotemeta($base_dir);
        $dir =~ s/$qdir//;

        print "$dir - $_\n";

    }, $base_dir);


}
