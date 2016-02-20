use strict;
use warnings;
package App::Spec::Option;

our $VERSION = '0.000'; # VERSION

use Moo;

has name => ( is => 'ro' );
has type => ( is => 'ro' );
has multiple => ( is => 'ro' );
has required => ( is => 'ro' );
has summary => ( is => 'ro' );
has description => ( is => 'ro' );
has default => ( is => 'ro' );
has filter => ( is => 'ro' );
has completion => ( is => 'ro' );
has aliases => ( is => 'ro' );

sub build {
    my ($class, $args) = @_;
    my $name;
    unless (ref $args) {
        $args = { name => $args };
    }
    my $description = $args->{description};
    my $summary = $args->{summary};
    $summary //= $description // '';
    $description //= $summary;
    my $type = $args->{type} // 'string';
    my $self = $class->new({
        name => $args->{name},
        type => $type,
        multiple => $args->{multiple} ? 1 : 0,
        required => $args->{required} ? 1 : 0,
        summary => $summary,
        description => $description,
        default => $args->{default},
        completion => $args->{completion},
        aliases => $args->{aliases} || [],
    });
    return $self;
}

1;
