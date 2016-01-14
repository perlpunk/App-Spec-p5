use strict;
use warnings;
package App::Spec::Run;
use 5.010;
our $VERSION = '0.000'; # VERSION

use List::Util qw/ any /;
use Data::Dumper;
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

    $self->check_help;

    my %option_specs;
    my @param_list;
    my $op = $self->process_commands_options(
        option_specs => \%option_specs,
        parameter_list => \@param_list,
    );

    my %param_specs;
    $self->process_parameters(
        parameter_list => \@param_list,
        param_specs => \%param_specs,
    );
    my $opt = App::Spec::Options->new({
        options => $self->options,
        option_specs => \%option_specs,
        parameters => $self->parameters,
        param_specs => \%param_specs,
    });
    my %errs;
    my ($ok) = $opt->process( \%errs, type => "parameters", app => $self );
    $ok &&= $opt->process( \%errs, type => "options", app => $self );

    unless ($ok) {
        my $err = Data::Dumper->Dump([\%errs], ['errs']);
        my $help = $spec->usage($self->commands);
        warn $help;
        die "$err\nsorry =(\n";
    }
    $self->$op;

}

sub process_parameters {
    my ($self, %args) = @_;
    my $param_list = $args{parameter_list};
    my %parameters;
    my $param_specs = $args{param_specs};
    for my $p (@$param_list) {
        my $name = $p->name;
        my $type = $p->type;
        my $multiple = $p->multiple;
        my $required = $p->required;
        my $value;
        if ($multiple) {
            $value = [@ARGV];
            @ARGV = ();
        }
        else {
            $value = shift @ARGV;
        }
        $parameters{ $name } = $value;
        $param_specs->{ $name } = $p;
    }
    $self->parameters(\%parameters);
}

sub process_commands_options {
    my ($self, %args) = @_;
    my %options;
    my @cmds;
    my $spec = $self->spec;
    my $option_specs = $args{option_specs};
    my $param_list = $args{parameter_list};
    my $global_options = $spec->options;
    my @getopt = $spec->make_getopt($global_options, \%options, $option_specs);
    GetOptions(@getopt);

    my $commands = $spec->subcommands;
    my $op;
    my $cmd_spec;
    my $subcommand_required = 1;
    while (keys %$commands) {
        my @k = keys %$commands;
        my $cmd = shift @ARGV;
        if (not defined $cmd and not $op) {
            warn $spec->usage(\@cmds);
            die "Missing subcommand(s)";
        }
        elsif (not defined $cmd) {
            last;
        }
        $cmd_spec = $commands->{ $cmd } or do {
            warn $spec->usage(\@cmds);
            die "Unknown subcommand '$cmd'";
        };
        $subcommand_required = $cmd_spec->{subcommand_required} // 1;
        my $cmd_options = $cmd_spec->options;
        my @getopt = $spec->make_getopt($cmd_options, \%options, $option_specs);
        GetOptions(@getopt);
        push @cmds, $cmd;
        $commands = $cmd_spec->subcommands || {};
        $op = $cmd_spec->op if $cmd_spec->op;
        @$param_list = @{ $cmd_spec->parameters };
    }
    my @names = sort keys %$commands;
    if (@names and $subcommand_required) {
        warn "Missing subcommand\n";
        my $help = $spec->usage(\@cmds);
        die $help;
    }
    unless ($op) {
        warn "Missing op for commands (@cmds)\n";
        my $help = $spec->usage(\@cmds);
        die $help;
    }
    $self->commands(\@cmds);
    $self->options(\%options);
    return $op;
}

sub check_help {
    GetOptions(
        "help" => \my $help,
    );

    if ($help and not $ARGV[0] eq "help") {
        # call subcommand 'help'
        unshift @ARGV, "help";
    }

}


sub cmd_help {
    my ($self) = @_;
    my $spec = $self->spec;
    my $cmds = $self->commands;
    shift @$cmds;
    my $help = $spec->usage($cmds);
    say $help;
}

sub cmd_self_completion {
    my ($self) = @_;
    my $options = $self->options;
    my $shell = $options->{zsh} ? "zsh" : $options->{bash} ? "bash" : '';
    unless ($shell) {
        my $ppid = getppid();
        chomp($shell = `ps --no-headers -o cmd $ppid`);
        $shell =~ s/.*\W(\w*sh).*$/$1/; #handling case of '-zsh' or '/bin/bash'
                                        #or bash -i -rs
    }
    unless (any { $_ eq $shell } qw/ bash zsh / ) {
        die "Specify which shell, '$shell' not supported";
    }
    my $spec = $self->spec;
    my $completion = $spec->generate_completion(
        shell => $shell,
    );
    say $completion;
}

1;
