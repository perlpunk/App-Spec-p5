# ABSTRACT: App::Spec framework to run your app
use strict;
use warnings;
package App::Spec::Run;
use 5.010;
our $VERSION = '0.000'; # VERSION

use List::Util qw/ any /;
use Data::Dumper;
use App::Spec::Options;
use Getopt::Long qw/ :config pass_through bundling /;
use Moo;

has spec => ( is => 'ro' );
has options => ( is => 'rw' );
has parameters => ( is => 'rw', default => sub { +{} } );
has commands => ( is => 'rw' );
has runmode => ( is => 'rw', default => 'normal' );
has errors => ( is => 'rw' );

sub run {
    my ($self) = @_;
    my $spec = $self->spec;

    my $completion_parameter = $ENV{PERL5_APPSPECRUN_COMPLETION_PARAMETER};
    my $op = $self->check_help;

    my %option_specs;
    my @param_list;
    my %param_specs;
    unless ($op) {
        $op = $self->process_commands_options(
            option_specs => \%option_specs,
            parameter_list => \@param_list,
            param_specs => \%param_specs,
        );
    }


    my $opt = App::Spec::Options->new({
        options => $self->options,
        option_specs => \%option_specs,
        parameters => $self->parameters,
        param_specs => \%param_specs,
    });
    my %errs;
    my ($ok) = $opt->process( \%errs, type => "parameters", app => $self );
    $ok &&= $opt->process( \%errs, type => "options", app => $self );
    $self->errors(\%errs) if not $ok;

    if (not $ok and not $completion_parameter) {
        $self->error_output;
    }
    if ($completion_parameter) {
        $self->completion_output(
            param_specs => \%param_specs,
            completion_parameter => $completion_parameter,
        );
    }
    else {
        $self->$op;
    }

}

sub completion_output {
    my ($self, %args) = @_;
    my $completion_parameter = $args{completion_parameter};
    my $param_specs = $args{param_specs};
    my $shell = $ENV{PERL5_APPSPECRUN_SHELL} or return;
    my $param = $param_specs->{ $completion_parameter };
    my $completion = $param->completion or return;
    my $op;
    if (ref $completion) {
        $op = $completion->{op} or return;
    }
    else {
        my $possible_values = $param->values or return;
        $op = $possible_values->{op} or return;
    }
    my $args = {
        runmode => "completion",
        parameter => $completion_parameter,
    };
    my $result = $self->$op($args);

    my $string = '';
    for my $item (@$result) {
        if (ref $item eq 'HASH') {
            my $name = $item->{name};
            my $desc = $item->{description};
            $string .= "$name\t$desc\n";
        }
        else {
            $string .= "$item\n";
        }
    }

    print $string;
    return;
}

sub error_output {
    my ($self) = @_;
    my $errs = $self->errors;
    my @error_output;
    for my $key (sort keys %$errs) {
        my $errors = $errs->{ $key };
        if ($key eq "parameters" or $key eq "options") {
            for my $name (sort keys %$errors) {
                my $error = $errors->{ $name };
                $key =~ s/s$//;
                push @error_output, "Error: $key '$name': $error";
            }
        }
        else {
            my $err = Data::Dumper->Dump([$errs], ['errs']);
            push @error_output, $err;
        }
    }
    $self->colorize and require Term::ANSIColor;
    my $help = $self->spec->usage(
        commands => $self->commands,
        highlights => $errs,
        color => $self->colorize,
    );
    say STDERR $help;
    for my $msg (@error_output) {
        $self->colorize
            and $msg = Term::ANSIColor::colored([qw/ bold red /], $msg);
        print STDERR "$msg\n";
    }
    die "sorry =(\n";
}

sub colorize {
    my ($self) = @_;
    if (($ENV{PERL5_APPSPECRUN_COLOR} // '') eq 'always') {
        return 1;
    }
    if (($ENV{PERL5_APPSPECRUN_COLOR} // '') eq 'never') {
        return 0;
    }
    if (-t STDOUT and -t STDERR) {
        return 1;
    }
    return 0;
}

sub process_parameters {
    my ($self, %args) = @_;
    my $param_list = $args{parameter_list};
    my $parameters = $self->parameters;
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
        $parameters->{ $name } = $value;
        $param_specs->{ $name } = $p;
    }
}

sub process_commands_options {
    my ($self, %args) = @_;
    my %options;
    my @cmds;
    my $spec = $self->spec;
    my $option_specs = $args{option_specs};
    my $param_specs = $args{param_specs};
    my $param_list = $args{parameter_list};
    my $global_options = $spec->options;
    my $global_parameters = $spec->parameters;
    push @$param_list, @{ $global_parameters };
    my @getopt = $spec->make_getopt($global_options, \%options, $option_specs);
    GetOptions(@getopt);

    $self->process_parameters(
        parameter_list => $param_list,
        param_specs => $param_specs,
    );



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

        $self->process_parameters(
            parameter_list => $param_list,
            param_specs => $param_specs,
        );
    }
    my @names = sort keys %$commands;
    unless ($op) {
        if ($spec->has_subcommands) {
            warn "Missing op for commands (@cmds)\n";
            my $help = $spec->usage(
                commands => \@cmds,
                color => $self->colorize,
            );
            die $help;
        }
        else {
            $op = "execute";
        }
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
    my ($self) = @_;
    GetOptions(
        "help|h" => \my $help,
    );

    my $op;
    if ($self->spec->has_subcommands) {
        if ($help and (not @ARGV or $ARGV[0] ne "help")) {
            # call subcommand 'help'
            unshift @ARGV, "help";
        }
    }
    else {
        if ($help) {
            $op = "cmd_help";
            unshift @ARGV, "--help";
        }
    }

    return $op;
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

sub cmd_self_pod {
    my ($self) = @_;
    my $spec = $self->spec;
    my $pod = $spec->generate_pod(
    );
    say $pod;
}

1;

__END__
=pod

=head1 DESCRIPTION

App::Spec::Run is the framework which runs your app defined by the spec.
Your app class should inherit from App::Spec::Run.

=head1 METHODS

=over 4

=item run

Actually runs your app

=back

=cut

