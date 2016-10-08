use strict;
use warnings;
package App::Spec::Option;

our $VERSION = '0.000'; # VERSION

use base 'App::Spec::Argument';
use Moo;

has aliases => ( is => 'ro' );

sub build {
    my ($class, $args) = @_;
    my %hash = $class->common($args);
    my $self = $class->new({
        %hash,
        aliases => $args->{aliases} || [],
    });
    return $self;
}

1;
