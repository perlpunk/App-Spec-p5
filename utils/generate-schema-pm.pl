#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use FindBin '$Bin';

use Data::Dumper;
use YAML::PP;

my $specfile = "$Bin/../share/schema.yaml";
my $pm = "$Bin/../lib/App/Spec/Schema.pm";

my $yp = YAML::PP->new( schema => [qw/ JSON /] );

my $SCHEMA = $yp->load_file($specfile);
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Indent = 1;
my $dump = Data::Dumper->Dump([$SCHEMA], ['SCHEMA']);

open my $fh, '<', $pm or die $!;
my $module = do { local $/; <$fh> };
close $fh;

$module =~ s/(# START INLINE\n).*(# END INLINE\n)/$1$dump$2/s;

open $fh, '>', $pm or die $!;
print $fh $module;
close $fh;
