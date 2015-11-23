use strict;
use warnings;
package App::Spec::Option;

our $VERSION = '0.000'; # VERSION

use Moo;

has name => ( is => 'ro' );
has type => ( is => 'ro' );
has required => ( is => 'ro' );
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
    my $self = $class->new({
        name => $args->{name},
        type => $args->{type} // 'string',
        required => $args->{required} ? 1 : 0,
        description => $args->{description} // '',
        default => $args->{default},
        completion => $args->{completion},
        aliases => $args->{aliases} || [],
    });
    return $self;
}

1;
