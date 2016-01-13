use strict;
use warnings;
package App::Spec::Command;

our $VERSION = '0.000'; # VERSION

use App::Spec::Option;
use App::Spec::Parameter;

use Moo;

has name => ( is => 'ro' );
has summary => ( is => 'ro' );
has description => ( is => 'ro' );
has options => ( is => 'ro' );
has parameters => ( is => 'ro' );
has op => ( is => 'ro' );
has subcommands => ( is => 'ro' );

sub build {
    my ($class, $args) = @_;
    my $options = $args->{options} || [];
    my $parameters = $args->{parameters} || [];
    my $subcommands = $args->{subcommands} || {};

    my @options;
    my @parameters;
    my %subcommands;

    for my $opt (@$options) {
        push @options, App::Spec::Option->build($opt);
    }
    for my $p (@$parameters) {
        push @parameters, App::Spec::Parameter->build($p);
    }
    for my $name (keys %$subcommands) {
        my $cmd = $subcommands->{ $name };
        $subcommands{ $name } = App::Spec::Command->build({
            name => $name,
            %$cmd
        });
    }

    my $self = $class->new({
        name => $args->{name},
        summary => $args->{summary},
        options => \@options,
        parameters => \@parameters,
        op => $args->{op},
        subcommands => \%subcommands,
        description => $args->{description},
    });
    return $self;
}

1;
