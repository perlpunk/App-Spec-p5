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

    if ($help and not $ARGV[0] eq "help") {
        # call subcommand 'help'
        unshift @ARGV, "help";
    }

    unless (@ARGV) {
        @ARGV = "help";
    }


    my %options;
    my %option_specs;
    my $global_options = $spec->options;
    my @getopt = $spec->make_getopt($global_options, \%options, \%option_specs);
    GetOptions(@getopt);

    my $commands = $spec->subcommands;
    my $parameters;
    my @cmds;
    my %parameters;
    my $op;
    my $cmd_spec;
    while (keys %$commands) {
        my @k = keys %$commands;
        my $cmd = shift @ARGV;
        if (not defined $cmd and not $op) {
            say $spec->usage(\@cmds);
            die "Missing subcommand(s)";
        }
        elsif (not defined $cmd) {
            last;
        }
        $cmd_spec = $commands->{ $cmd } or do {
            say $spec->usage(\@cmds);
            die "Unknown subcommand '$cmd'";
        };
        my $options = $cmd_spec->options;
        my @getopt = $spec->make_getopt($options, \%options, \%option_specs);
        GetOptions(@getopt);
        push @cmds, $cmd;
        $commands = $cmd_spec->subcommands || {};
        $op = $cmd_spec->op if $cmd_spec->op;
        $parameters = $cmd_spec->parameters;
    }
    unless ($op) {
        my $subcommands = $commands;
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

    $self->options(\%options);
    $self->parameters(\%parameters);
    $self->commands(\@cmds);
    unless ($ok) {
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%errs], ['errs']);
        my $help = $spec->usage(\@cmds);
        say $help;
        die "sorry =(\n";
    }
    $self->$op;

}

sub cmd_help {
    my ($self) = @_;
    my $spec = $self->spec;
    my $cmds = $self->commands;
    shift @$cmds;
    my $help = $spec->usage($cmds);
    say $help;
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
