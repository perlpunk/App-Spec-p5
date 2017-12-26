# ABSTRACT: App::Spec objects representing command line option specs
use strict;
use warnings;
package App::Spec::Option;

our $VERSION = '0.000'; # VERSION

use Moo;
extends 'App::Spec::Argument';

has aliases => ( is => 'ro', default => sub { [] } );

sub build {
    my ($class, @args) = @_;
    return $class->new(@args);
}

1;

=pod

=head1 NAME

App::Spec::Option - App::Spec objects representing command line option specs

=head1 SYNOPSIS

This class inherits from L<App::Spec::Argument>

=head1 METHODS

=over 4

=item build

    my $option = App::Spec::Option->build(
        name => 'verbose',
        summary => 'lala',
        aliases => ['v'],
    );

=item aliases

Attribute which represents the one from the spec.

=back

=cut
