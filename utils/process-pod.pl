#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use 5.010;

my $argument = "lib/App/Spec/Argument.pm";

my @processed;
open my $fh, "<", $argument;
my @content;
while (my $line = <$fh>) {
    if (my $row = ($line =~ m/^START INLINE (\S+)/ ... $line =~ m/^STOP INLINE/)) {
        my $file = $1;
        warn "$row: $line";
        if ($row =~ m/E0$/) {
            push @processed, "\n", "=for comment\n", $line;
            @content = ();
        }
        if ($row == 1) {
            open my $inline, "<", $file or die $!;
            @content = map { "    $_" } grep { not m/^# vim/ } <$inline>;
            close $inline;
            push @processed, $line, "\n", @content;
        }
        elsif ($row == 2) {
            push @processed, $line;
        }
    }
    else {
        push @processed, $line;
    }
}
close $fh;

open $fh, ">", $argument;
print $fh @processed;
close $fh;
