#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use SPPM::Web;

SPPM::Web->setup_engine('PSGI');
my $app = sub { SPPM::Web->run(@_) };

