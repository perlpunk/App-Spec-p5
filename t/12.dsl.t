#!/usr/bin/env perl
use strict;
use warnings;
use constant TESTS => 8;
use Test::More tests => TESTS;

use FindBin '$Bin';
use YAML::XS qw/ LoadFile /;
use App::Spec;
use Test::Deep;
use Data::Dumper;

my @docs = LoadFile("$Bin/data/12.dsl.yaml");
my $spec1 = App::Spec->read($docs[0]);
my $spec2 = App::Spec->read($docs[1]);

for my $i (0 .. TESTS - 1) {
    my $dsl = $spec1->options->[$i];
    my $compare = $spec2->options->[$i];
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$dsl], ['dsl']);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$compare], ['compare']);

    cmp_deeply(
        $dsl,
        $compare,
        "dsl: option $i",
    );
}
