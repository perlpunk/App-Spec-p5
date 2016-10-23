# ABSTRACT: App::Spec objects representing command line option specs
use strict;
use warnings;
package App::Spec::Option;

our $VERSION = '0.000'; # VERSION

use base 'App::Spec::Argument';
use Moo;

has aliases => ( is => 'ro' );

sub build {
    my ($class, %args) = @_;
    my %hash = $class->common(%args);
    my $self = $class->new({
        aliases => $args{aliases} || [],
        %hash,
    });
    return $self;
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

=back

=cut
