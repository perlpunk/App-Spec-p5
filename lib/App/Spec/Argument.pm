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
    unless (ref $args) {
        $args = { name => $args };
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
    );
    return %hash;
}

1;
