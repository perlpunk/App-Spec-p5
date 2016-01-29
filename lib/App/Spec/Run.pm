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

    my $completion_parameter = $ENV{PERL5_APPSPECRUN_COMPLETION_PARAMETER};
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

    my %options_config;
    if ($completion_parameter) {
        $options_config{required} = "ignore";
        $options_config{default} = "ignore";
    }

    my $opt = App::Spec::Options->new({
        options => $self->options,
        option_specs => \%option_specs,
        parameters => $self->parameters,
        param_specs => \%param_specs,
        config => \%options_config,
    });
    my %errs;
    my ($ok) = $opt->process( \%errs, type => "parameters", app => $self );
    $ok &&= $opt->process( \%errs, type => "options", app => $self );

    unless ($ok) {
        my $err = Data::Dumper->Dump([\%errs], ['errs']);
        my $help = $spec->usage(
            commands => $self->commands,
            highlights => \%errs,
            color => $self->colorize,
        );
        print STDERR $help;
        die "$err\nsorry =(\n";
    }
    my $args = {};
    if ($completion_parameter) {
        my $shell = $ENV{PERL5_APPSPECRUN_SHELL} or return;
        my $param = $param_specs{ $completion_parameter };
        my $completion = $param->completion;
        my $op = $completion->{op} or return;
        $args->{completion} = {
            parameter => $completion_parameter,
        };
        my $result = $self->$op($args);
        my $mod;
        if ($shell eq 'bash') {
            $mod = 'App::Spec::Completion::Bash';
        }
        elsif ($shell eq 'zsh') {
            $mod = 'App::Spec::Completion::Zsh';
        }
        else {
            return;
        }
        eval "use $mod";
        my $string = $mod->list_to_alternative(
            name => $completion_parameter,
            list => $result,
        );
        say $string;
    }
    else {
        $self->$op;
    }

}

sub colorize {
    my ($self) = @_;
    if (($ENV{PERL5_APPSPECRUN_COLOR} // '') eq 'always') {
        return 1;
    }
    if (($ENV{PERL5_APPSPECRUN_COLOR} // '') eq 'never') {
        return 0;
    }
    if (-t STDOUT and -d STDERR) {
        return 1;
    }
    return 0;
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
        if (not defined $cmd) {
            if (not $op or $subcommand_required) {
                warn $spec->usage(
                    commands => \@cmds,
                    color => $self->colorize,
                    highlights => {
                        subcommands => 1,
                    },
                );
                die $self->error("Missing subcommand(s)");
            }
            last;
        }
        $cmd_spec = $commands->{ $cmd } or do {
            warn $spec->usage(
                commands => \@cmds,
                color => $self->colorize,
                highlights => {
                    subcommands => 1,
                },
            );
            die $self->error("Unknown subcommand '$cmd'");
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
    unless ($op) {
        warn "Missing op for commands (@cmds)\n";
        my $help = $spec->usage(
            commands => \@cmds,
            color => $self->colorize,
        );
        die $help;
    }
    $self->commands(\@cmds);
    $self->options(\%options);
    return $op;
}

sub error {
    my ($self, $msg) = @_;
    require Term::ANSIColor;
    $self->colorize
        and $msg = Term::ANSIColor::colored([qw/ bold red /], $msg);
    return "$msg\n";
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
    my $help = $spec->usage(
        commands => $cmds,
        color => $self->colorize,
    );
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
