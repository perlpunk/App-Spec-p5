use strict;
use warnings;
package App::Spec::Parameter;

our $VERSION = '0.000'; # VERSION

use base 'App::Spec::Argument';
use Moo;

sub build {
    my ($class, $args) = @_;
    my %hash = $class->common($args);
    my $self = $class->new({
        %hash,
    });
    return $self;
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
