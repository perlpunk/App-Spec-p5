# ABSTRACT: App::Spec framework to run your app
use strict;
use warnings;
package App::Spec::Run;
use 5.010;
our $VERSION = '0.000'; # VERSION

use List::Util qw/ any /;
use Data::Dumper;
use App::Spec::Run::Validator;
use App::Spec::Run::Response;
use Getopt::Long qw/ :config pass_through bundling /;
use Ref::Util qw/ is_arrayref /;
use Moo;

has spec => ( is => 'ro' );
has options => ( is => 'rw' );
has parameters => ( is => 'rw', default => sub { +{} } );
has commands => ( is => 'rw' );
has runmode => ( is => 'rw', default => 'normal' );
has errors => ( is => 'rw' );
has op => ( is => 'rw' );
has cmd => ( is => 'rw' );
has response => ( is => 'rw' );

sub process {
    my ($self) = @_;

    my $res = $self->response;
    unless ($res) {
        $res = App::Spec::Run::Response->new;
        $self->response($res);
    }

    my $completion_parameter = $ENV{PERL5_APPSPECRUN_COMPLETION_PARAMETER};
    $self->check_help;

    my %option_specs;
    my %param_specs;
    unless ($self->op) {
        $self->process_input(
            option_specs => \%option_specs,
            param_specs => \%param_specs,
        );
    }

    unless ($self->response->halted) {
        my $opt = App::Spec::Run::Validator->new({
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
    }

    unless ($self->response->halted) {

        my $op = $self->op;

        if ($completion_parameter) {
            $self->completion_output(
                param_specs => \%param_specs,
                completion_parameter => $completion_parameter,
            );
        }
        else {
            $self->cmd->$op($self);
        }
    }

}

sub run {
    my ($self) = @_;

    $self->process;

    $self->finish;

}

sub out {
    my ($self, $text) = @_;
    my $res = $self->response;
    $text .= "\n" unless $text =~ m/\n\z/;
    $res->add_output($text);
}

sub err {
    my ($self, $text) = @_;
    my $res = $self->response;
    $text .= "\n" unless $text =~ m/\n\z/;
    $res->add_error($text);
}

sub halt {
    my ($self, $exit) = @_;
    $self->response->halted(1);
    $self->response->exit($exit || 0);
}

sub finish {
    my ($self) = @_;
    my $res = $self->response;
    $res->print_output;
    $res->finished(1);
    if (my $exit = $res->exit) {
        exit $exit;
    }
}

sub completion_output {
    my ($self, %args) = @_;
    my $completion_parameter = $args{completion_parameter};
    my $param_specs = $args{param_specs};
    my $shell = $ENV{PERL5_APPSPECRUN_SHELL} or return;
    my $param = $param_specs->{ $completion_parameter };
    my $unique = $param->{unique};
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
    my $result = $self->cmd->$op($self, $args);

    my $string = '';
    my %seen;
    if ($unique) {
        my $params = $self->parameters;
        my $value = $params->{ $completion_parameter };
        $value = [$value] unless is_arrayref $value;
        @seen{ @$value } = (1) x @$value;
    }
    for my $item (@$result) {
        if (ref $item eq 'HASH') {
            my $name = $item->{name};
            $unique and $seen{ $name }++ and next;
            my $desc = $item->{description};
            $string .= "$name\t$desc\n";
        }
        else {
            $unique and $seen{ $item }++ and next;
            $string .= "$item\n";
        }
    }

    $self->out($string);
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
    my $help = $self->spec->usage(
        commands => $self->commands,
        highlights => $errs,
        colored => $self->colorize_code('err'),
    );
    $self->err($help);
    for my $msg (@error_output) {
        $self->colorize
            and $msg = $self->colored('err', [qw/ error /], $msg);
        $self->err("$msg\n");
    }
    $self->halt(1);
}

sub colorize_code {
    my ($self, $out) = @_;
    $self->colorize($out)
        ? sub {
            my $colored = $self->colored($out, $_[0], $_[1]);
            unless (defined wantarray) {
                $_[1] = $colored;
            }
            return $colored;
        }
        : sub { $_[1] },
}

sub colorize {
    my ($self, $out) = @_;
    $out ||= 'out';
    if (($ENV{PERL5_APPSPECRUN_COLOR} // '') eq 'always') {
        return 1;
    }
    if (($ENV{PERL5_APPSPECRUN_COLOR} // '') eq 'never') {
        return 0;
    }
    if ($out eq 'out' and -t STDOUT or $out eq 'err' and -t STDERR) {
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

sub process_input {
    my ($self, %args) = @_;
    my %options;
    my @cmds;
    my $spec = $self->spec;
    my $option_specs = $args{option_specs};
    my $param_specs = $args{param_specs};
    my $global_options = $spec->options;
    my $global_parameters = $spec->parameters;
    my @getopt = $spec->make_getopt($global_options, \%options, $option_specs);
    GetOptions(@getopt);

    $self->process_parameters(
        parameter_list => $global_parameters,
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
                $self->err($spec->usage(
                    commands => \@cmds,
                    colored => $self->colorize_code('err'),
                    highlights => {
                        subcommands => 1,
                    },
                ));
                $self->err( $self->error("Missing subcommand(s)") );
                $self->halt(1);
            }
            last;
        }
        $cmd_spec = $commands->{ $cmd } or do {
            $self->err($spec->usage(
                commands => \@cmds,
                colored => $self->colorize_code('err'),
                highlights => {
                    subcommands => 1,
                },
            ));
            $self->err( $self->error("Unknown subcommand '$cmd'") );
            $self->halt(1);
            last;
        };
        $subcommand_required = $cmd_spec->{subcommand_required} // 1;
        my $cmd_options = $cmd_spec->options;
        my @getopt = $spec->make_getopt($cmd_options, \%options, $option_specs);
        GetOptions(@getopt);
        push @cmds, $cmd;
        $commands = $cmd_spec->subcommands || {};
        $op = $cmd_spec->op if $cmd_spec->op;

        $self->process_parameters(
            parameter_list => $cmd_spec->parameters,
            param_specs => $param_specs,
        );
    }

    unless ($self->response->halted) {
        unless ($op) {
            if ($spec->has_subcommands) {
                $self->err( "Missing op for commands (@cmds)\n" );
                my $help = $spec->usage(
                    commands => \@cmds,
                    colored => $self->colorize_code('err'),
                );
                $self->err( $help );
                $self->halt(1);
            }
            else {
                $op = "execute";
            }
        }
        $self->commands(\@cmds);
        $self->options(\%options);
        $self->op($op);
        return $op;
    }

    return;
}

sub error {
    my ($self, $msg) = @_;
    $msg = $self->colored('err', [qw/ error /], $msg) . "\n";
}

sub colored {
    my ($self, $out, $colors, $msg) = @_;
    $colors = [ map { $_ eq 'error' ? qw/ bold red / : $_ } @$colors ];
    require Term::ANSIColor;
    $self->colorize($out)
        and $msg = Term::ANSIColor::colored($colors, $msg);
    return $msg;
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

    $self->op($op);
}


sub cmd_help {
    my ($run) = @_;
    my $spec = $run->spec;
    my $cmds = $run->commands;
    shift @$cmds;
    my $help = $spec->usage(
        commands => $cmds,
        colored => $run->colorize_code,
    );
    $run->out($help);
}

sub cmd_self_completion {
    my ($run) = @_;
    my $options = $run->options;
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
    my $spec = $run->spec;
    my $completion = $spec->generate_completion(
        shell => $shell,
    );
    $run->out($completion);
}

sub cmd_self_pod {
    my ($run) = @_;
    my $spec = $run->spec;
    my $pod = $spec->generate_pod(
    );
    $run->out($pod);
}

1;

__END__
=pod

=head1 DESCRIPTION

App::Spec::Run is the framework which runs your app defined by the spec.
Your app class should inherit from App::Spec::Run::Cmd.

=head1 METHODS

=over 4

=item run

Actually runs your app

=back

=cut

