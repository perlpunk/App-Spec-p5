use strict;
use warnings;
package App::Spec::Argument;

our $VERSION = '0.000'; # VERSION

use Moo;

has name => ( is => 'ro' );
has type => ( is => 'ro' );
has multiple => ( is => 'ro' );
has required => ( is => 'ro' );
has unique => ( is => 'ro' );
has summary => ( is => 'ro' );
has description => ( is => 'ro' );
has default => ( is => 'ro' );
has filter => ( is => 'ro' );
has completion => ( is => 'ro' );
has enum => ( is => 'ro' );
has values => ( is => 'ro' );

sub common {
    my ($class, $args) = @_;
    my %dsl;
    if (defined $args->{spec}) {
        %dsl = $class->from_dsl(delete $args->{spec});
    }
    my $description = $args->{description};
    my $summary = $args->{summary};
    $summary //= $description // '';
    $description //= $summary;
    my $type = $args->{type} // 'string';
    my %hash = (
        name => $args->{name},
        summary => $summary,
        description => $description,
        type => $type,
        multiple => $args->{multiple} ? 1 : 0,
        required => $args->{required} ? 1 : 0,
        unique => $args->{unique} ? 1 : 0,
        default => $args->{default},
        completion => $args->{completion},
        enum => $args->{enum},
        values => $args->{values},
        filter => $args->{filter},
        %dsl,
    );
    not defined $hash{ $_ } and delete $hash{ $_ } for keys %hash;
    return %hash;
}

my $name_re = qr{\w+};

sub from_dsl {
    my ($class, $dsl) = @_;
    my %hash;

    my $name;
    my $type = "flag";
    my $multiple = 0;
    my$required = 0;
    $dsl =~ s/^\s+//;

    if ($dsl =~ s/^\+//) {
        $required = 1;
    }

    if ($dsl =~ s/^ ($name_re) //x) {
        $name = $1;
        $hash{name} = $name;
    }
    else {
        die "invalid spec: '$dsl'";
    }

    my @aliases;
    while ($dsl =~ s/^ \| (\w) //x) {
        push @aliases, $1;
    }
    if (@aliases) {
        $hash{aliases} = \@aliases;
    }

    my $getopt_type = '';
    if ($dsl =~ s/^=//) {
        # not a flag, default string
        $type = "string";
        # TODO support all of Getopt::Long types
        if ($dsl =~ s/^([is])//) {
            $getopt_type = $1;
            if ($getopt_type eq "i") {
                $type = "integer";
            }
            elsif ($getopt_type eq "s") {
            }
            else {
                die "Option $name: type $getopt_type not supported";
            }
        }
    }

    if ($type eq 'flag' and $dsl =~ s/^\+//) {
        # incremental flag
        $multiple = 1;
    }
    elsif ($type eq 'string' and $dsl =~ s/^\@//) {
        $multiple = 1;
    }

    $dsl =~ s/^\s+//;

    if ($dsl =~ s/^\+(\w+)//) {
        $type = $1;
        if ($getopt_type and $type ne $getopt_type) {
            die "Explicit type '$type' conflicts with getopt type '$getopt_type'";
        }
    }

    $dsl =~ s/^\s+//;

    if ($dsl =~ s/^--\s*(.*)//) {
        # TODO only summary should be supported
        $hash{summary} = $1;
        $hash{description} = $1;
    }

    if (length $dsl) {
        die "Invalid spec: trailing '$dsl'";
    }

    $hash{type} = $type;
    $hash{multiple} = $multiple;
    $hash{required} = $required;
    return %hash;
}

1;
