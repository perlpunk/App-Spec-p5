use strict;
use warnings;
package App::Spec::Run;

use 5.010;

our $VERSION = '0.000'; # VERSION


use Getopt::Long qw/ :config pass_through /;
use Moo;

has spec => ( is => 'ro' );
has options => ( is => 'rw' );
has parameters => ( is => 'rw' );
has commands => ( is => 'rw' );

sub run {
    my ($self) = @_;
    my $spec = $self->spec;

    GetOptions(
        "help" => \my $help,
    );

    if ($help) {
        # call subcommand 'help'
        unshift @ARGV, "help";
    }

    unless (@ARGV) {
        @ARGV = "help";
    }

    my $commands = $spec->commands;

    my %options;
    my $global_options = $spec->options;
    my @getopt = $spec->make_getopt($global_options, \%options);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@getopt], ['getopt']);
    GetOptions(@getopt);

    my $parameters;
    my @commands;
    my %parameters;
    my $op;
    while (my $cmd = shift @ARGV) {
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$cmd], ['cmd']);
        my $cmd_spec = $commands->{ $cmd } or die "Unknown subcommand '$cmd'";
        my $options = $cmd_spec->{options} || [];
        my @getopt = $spec->make_getopt($options, \%options);
        GetOptions(@getopt);
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@getopt], ['getopt']);
#        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%options], ['options']);
        push @commands, $cmd;
        my $subcommands = $cmd_spec->{subcommands} || {};
        $commands = $subcommands;
        $op = $cmd_spec->op if $cmd_spec->op;
        $parameters = $cmd_spec->parameters;
        last unless %$subcommands;
    }
    unless ($op) {
        die "Missing op for commands (@commands)";
    }

    for my $p (@$parameters) {
        my $name = $p->name;
        my $type = $p->type;
        my $value = shift @ARGV;
        if ($p->required) {
            unless (defined $value) {
                die "Missing parameter '$name'";
            }
            my $filter = $p->filter;
            if ($filter) {
                my $method = $filter->{method};
                $value = $self->$method($value);
            }
            if ($type eq 'file') {
                unless (-e $value) {
                    die "Invalid value for parameter '$name': File '$value' does not exist";
                }
            }
        }
        $parameters{ $name } = $value;
    }

    $self->options(\%options);
    $self->parameters(\%parameters);
    $self->commands(\@commands);
    $self->$op;

}

sub cmd_help {
    my ($self) = @_;
    my $spec = $self->spec;
    my @cmds = @ARGV;
    my $help = $spec->usage(\@cmds);
}

sub cmd_self_completion_bash {
    my ($self) = @_;
    my $options = $self->options;
    my $parameters = $self->parameters;
}

sub cmd_self_completion_zsh {
    my ($self) = @_;
#    my $options = $self->options;
    my $parameters = $self->parameters;

    my $spec = $self->spec;
    my $completion = $spec->generate_completion(
        shell => "zsh",
    );
    say $completion;
}


1;
