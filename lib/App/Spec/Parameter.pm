# ABSTRACT: App::Spec objects representing command line parameters
use strict;
use warnings;
package App::Spec::Parameter;

our $VERSION = '0.000'; # VERSION

use Moo;
extends 'App::Spec::Argument';

sub build {
    my ($class, @args) = @_;
    return $class->new(@args);
}

sub to_usage_header {
    my ($self) = @_;
    my $name = $self->name;
    my $usage = '';
    if ($self->multiple and $self->required) {
        $usage = "<$name>+";
    }
    elsif ($self->multiple) {
        $usage = "[<$name>+]";
    }
    elsif ($self->required) {
        $usage = "<$name>";
    }
    else {
        $usage = "[<$name>]";
    }
}

1;

=pod

=head1 NAME

App::Spec::Parameter - App::Spec objects representing command line parameters

=head1 SYNOPSIS

This class inherits from L<App::Spec::Argument>

=head1 METHODS

=over 4

=item build

    my $param = App::Spec::Parameter->build(
        name => 'verbose',
        summary => 'lala',
    );

=item to_usage_header

    my $param_usage_header = $param->to_usage_header;
    # results
    # if multiple and required
    # <$name>+
    # if multiple
    # [<$name>+]
    # if required
    # <$name>
    # else
    # [<$name>}

=back

=cut
