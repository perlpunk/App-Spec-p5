use strict;
use warnings;
package App::Spec::Parameter;

our $VERSION = '0.000'; # VERSION

use Moo;

has name => ( is => 'ro' );
has type => ( is => 'ro' );
has multiple => ( is => 'ro' );
has required => ( is => 'ro' );
has summary => ( is => 'ro' );
has description => ( is => 'ro' );
has default => ( is => 'ro' );
has completion => ( is => 'ro' );
has filter => ( is => 'ro' );

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
    my $self = $class->new({
        name => $args->{name},
        type => $args->{type} // 'string',
        multiple => $args->{multiple} ? 1 : 0,
        required => $args->{required} ? 1 : 0,
        summary => $summary,
        description => $description,
        default => $args->{default},
        completion => $args->{completion},
        filter => $args->{filter},
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
