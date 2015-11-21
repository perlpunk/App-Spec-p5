use strict;
use warnings;
package App::Spec::Run;

use 5.010;

our $VERSION = '0.000'; # VERSION

use App::Spec::Options;

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
    my %option_specs;
    my $global_options = $spec->options;
    my @getopt = $spec->make_getopt($global_options, \%options, \%option_specs);
    GetOptions(@getopt);

    my $parameters;
    my @cmds;
    my %parameters;
    my $op;
    my $cmd_spec;
    while (my $cmd = shift @ARGV) {
        $cmd_spec = $commands->{ $cmd } or die "Unknown subcommand '$cmd'";
        my $options = $cmd_spec->{options} || [];
        my @getopt = $spec->make_getopt($options, \%options, \%option_specs);
        GetOptions(@getopt);
        push @cmds, $cmd;
        my $subcommands = $cmd_spec->subcommands || {};
        $commands = $subcommands;
        $op = $cmd_spec->op if $cmd_spec->op;
        $parameters = $cmd_spec->parameters;
        last unless %$subcommands;
    }
    unless ($op) {
        my $subcommands = $cmd_spec->subcommands || {};
        my @names = sort keys %$subcommands;
        if (@names) {
            warn "Missing subcommand (one of (@names))\n";
        }
        else {
            warn "Missing op for commands (@cmds)\n";
        }
        my $help = $spec->usage(\@cmds);
        say $help;
        exit;
    }

    my %param_specs;
    for my $p (@$parameters) {
        my $name = $p->name;
        my $type = $p->type;
        my $value = shift @ARGV;
        $parameters{ $name } = $value;
        $param_specs{ $name } = $p;
    }
    my $opt = App::Spec::Options->new({
        options => \%options,
        option_specs => \%option_specs,
        parameters => \%parameters,
        param_specs => \%param_specs,
    });
    my %errs;
    my ($ok) = $opt->process( \%errs, type => "parameters", app => $self );
    $ok &&= $opt->process( \%errs, type => "options", app => $self );

    unless ($ok) {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%errs], ['errs']);
        die "sorry =(\n";
    }
    $self->options(\%options);
    $self->parameters(\%parameters);
    $self->commands(\@cmds);
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
    my $spec = $self->spec;
    my $completion = $spec->generate_completion(
        shell => "bash",
    );
    say $completion;
}

sub cmd_self_completion_zsh {
    my ($self) = @_;

    my $spec = $self->spec;
    my $completion = $spec->generate_completion(
        shell => "zsh",
    );
    say $completion;
}


1;
