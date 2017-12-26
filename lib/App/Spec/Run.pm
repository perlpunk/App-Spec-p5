# ABSTRACT: App::Spec framework to run your app
use strict;
use warnings;
package App::Spec::Run;
use 5.010;
our $VERSION = '0.000'; # VERSION

use App::Spec::Run::Validator;
use App::Spec::Run::Response;
use App::Spec::Types qw/ AppSpec ArgumentValue ValidationErrors CommandOp RunResponse EventSubscriber /;
use Getopt::Long qw/ :config pass_through bundling /;
use Ref::Util qw/ is_arrayref /;
use Types::Standard qw/ Map Str ArrayRef Object /;
use Moo;

has spec => ( is => 'ro', required => 1, isa => AppSpec );
has options => ( is => 'rw', isa => Map[Str,ArgumentValue] );
has parameters => ( is => 'rw', isa => Map[Str,ArgumentValue], default => sub { +{} } );
has commands => ( is => 'rw', isa => ArrayRef[Str] );
has argv => ( is => 'rw', isa => ArrayRef[Str] );
has argv_orig => ( is => 'rw', isa => ArrayRef[Str] );
#has runmode => ( is => 'rw', default => 'normal' );
has validation_errors => ( is => 'rw', isa => ValidationErrors );
has op => ( is => 'rw', isa => CommandOp );
has cmd => ( is => 'rw', isa => Object );
has response => ( is => 'rw', isa => RunResponse, default => sub { App::Spec::Run::Response->new } );
has subscribers => ( is => 'rw', isa => Map[Str,EventSubscriber], default => sub { +{} } );

my %EVENTS = (
    print_output => 1,
    global_options => 1,
);

sub process {
    my ($self) = @_;

    my $plugins = $self->spec->plugins || [];
    for my $plugin (@$plugins) {
        $plugin->init_run($self);
    }
    my @callbacks;
    my $subscriber_events = $self->subscribers;
    for my $key (qw/ global_options print_output /) {
        my $subscribers = $subscriber_events->{ $key };
        for my $sub (@$subscribers) {
            my $plugin = $sub->{plugin};
            my $method = $sub->{method};
            my $callback = sub {
                $plugin->$method( run => $self, @_);
            };
            push @callbacks, $callback;
        }
        $self->response->add_callbacks($key => \@callbacks);
    }

    my $argv = $self->argv;
    unless ($argv) {
        $argv = \@ARGV;
        $self->argv($argv);
        $self->argv_orig([ @$argv ]);
    }

    my $completion_parameter = $ENV{PERL5_APPSPECRUN_COMPLETION_PARAMETER};

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
        my $ok = $opt->process( $self, \%errs );
        unless ($ok) {
            $self->validation_errors(\%errs);
            # if we are in completion mode, some errors might be ok
            if (not $completion_parameter) {
                $self->error_output;
            }
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
            $self->run_op($op);
        }
    }

}

sub run {
    my ($self) = @_;

    $self->process;

#    $self->event_processed;
    $self->finish;

}

sub run_op {
    my ($self, $op, $args) = @_;
    $self->cmd->$op($self, $args);
}

sub out {
    my ($self, $text) = @_;
    $text .= "\n" if (not ref $text and $text !~ m/\n\z/);
    $self->response->add_output($text);
}

sub err {
    my ($self, $text) = @_;
    $text .= "\n" if (not ref $text and $text !~ m/\n\z/);
    $self->response->add_error($text);
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
    my $result = $self->run_op($op, $args);

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
    my $errs = $self->validation_errors;
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
            require Data::Dumper;
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
        $msg = $self->colored('err', [qw/ error /], $msg);
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
            $value = [@{ $self->argv }];
            @{ $self->argv } = ();
        }
        else {
            $value = shift @{ $self->argv };
        }
        $parameters->{ $name } = $value;
        $param_specs->{ $name } = $p;
    }
}

sub process_input {
    my ($self, %args) = @_;
    my %options;
    $self->options(\%options);
    my @cmds;
    my $spec = $self->spec;
    my $option_specs = $args{option_specs};
    my $param_specs = $args{param_specs};
    my $global_options = $spec->options;
    my $global_parameters = $spec->parameters;
    my @getopt = $spec->make_getopt($global_options, \%options, $option_specs);
    GetOptions(@getopt);
    $self->event_globaloptions;
    my $op = $self->op;

    $self->process_parameters(
        parameter_list => $global_parameters,
        param_specs => $param_specs,
    );



    my $commands = $spec->subcommands;
    my $opclass = $self->spec->class;
    my $cmd_spec;
    my $subcommand_required = 1;
    while (keys %$commands) {
        my $cmd = shift @{ $self->argv };
        if (not defined $cmd) {
            if (not $op or $subcommand_required) {
                $self->err($spec->usage(
                    commands => \@cmds,
                    colored => $self->colorize_code('err'),
                    highlights => {
                        subcommands => 1,
                    },
                ));
                $self->err( $self->colorize_error("Missing subcommand(s)") );
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
            $self->err( $self->colorize_error("Unknown subcommand '$cmd'") );
            $self->halt(1);
            last;
        };
        $subcommand_required = $cmd_spec->{subcommand_required} // 1;
        my $cmd_options = $cmd_spec->options;
        my @getopt = $spec->make_getopt($cmd_options, \%options, $option_specs);
        GetOptions(@getopt);
        push @cmds, $cmd;
        $commands = $cmd_spec->subcommands || {};
        $op = '::' . $cmd_spec->op if $cmd_spec->op;
        $opclass = $cmd_spec->class if $cmd_spec->class;

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
                $op = "::execute";
            }
        }
        $self->commands(\@cmds);
        $self->options(\%options);
        if ($op =~ m/^::/) {
            $op = $opclass . $op;
        }
        $self->op($op);
        return $op;
    }

    return;
}

sub colorize_error {
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

sub subscribe {
    my ($self, %args) = @_;

    for my $event (sort keys %args) {
        next unless exists $EVENTS{ $event };
        my $info = $args{ $event };
        push @{ $self->subscribers->{ $event } }, $info;
    }

}

sub event_globaloptions {
    my ($self) = @_;

    my $subscribers = $self->subscribers->{global_options};
    for my $sub (@$subscribers) {
        my $plugin = $sub->{plugin};
        my $method = $sub->{method};
        $plugin->$method( run => $self);
    }
}

#sub event_processed {
#    my ($self) = @_;
#    my $plugins = $self->spec->plugins_by_type->{GlobalOptions};
#    for my $plugin (@$plugins) {
#        next unless $plugin->can("event_processed");
#        $plugin->event_processed(
#            run => $self,
#        );
#    }
#}

1;

__END__
=pod

=head1 NAME

App::Spec::Run - App::Spec framework to run your app

=head1 DESCRIPTION

App::Spec::Run is the framework which runs your app defined by the spec.
Your app class should inherit from L<App::Spec::Run::Cmd>.

=head1 SYNOPSIS

    sub your_command {
        my ($self, $run) = @_;
        my $options = $run->options;
        $run->out("It works");
    }

=head1 METHODS

=over 4

=item Constructor

You can create the object yourself like this:

    my $run = App::Spec::Run->new(
        spec => $appspec,
        cmd => App::YourApp->new,
    );

Or you use the runner method of L<App::Spec>, which will create it for you:

    my $run = $appspec->runner(...);

Both methods take optional arguments:

    my $run = App::Spec::Run->new(
        spec => $appspec,
        cmd => App::YourApp->new,

        # Custom array instead of the default ARGV.
        # The contents of this array will be modified
        argv => \@my_arguments,
    );

=item run

    $run->run;

Actually runs your app. Calls C<process> and C<finish>.

=item process

    $run->process;

Processes input, validates, runs your command and fills the
response object.

Does not print the output and does not exit.

=item out

    $run->out("Hello world!");

Appends to response output. Adds a newline if not present. You can also
pass a data structure:

    $run->out($hashref);

This will be formatted with L<Data::Dumper>.

See also L<App::Spec::Plugin::Format>.

=item err

    $run->err("Oops, that went wrong");

Appends to response error output. Adds a newline if not present

=item halt

    $run->halt;

Further processing is halted.

=item finish

    $run->finish;

Prints the output and exits with the exit code stored in C<response>.

=item process_input

    $run->process_input(
        option_specs => \%option_specs,
        param_specs => \%param_specs,
    );

=item process_parameters

    $run->process_parameters(
        parameter_list => $global_parameters,
        param_specs => $param_specs,
    );

=item run_op

    $run->run_op("yourcommand");
    # shortcut for
    $run->cmd->yourcommand($run);

=item completion_output

    $run->completion_output(
        param_specs => \%param_specs,
        completion_parameter => $completion_parameter,
    );

Is called when in completion mode

=item colored

Returns the given text colored, if colors are active for the given
output.

    $msg = $run->colored('err', [qw/ error /], "Oops");
    $msg = $run->colored('out', [qw/ green /], "Everything is fine!");

=item colorize

    my $color_active = $run->colorize('out');
    my $color_error_active = $run->colorize('err');

Returns 1 or 0 if given output color are active. That means, the output
is going to a terminal instead of being redirected.

=item colorize_code

    my $colored = $run->colorize_code('out');
    my $text = $colored->(['green'], "Hurray");
    # or
    my $text = "Hurray";
    $colored->(['green'], $text);

Returns a coderef which you can use for coloring

=item colorize_error

    my $msg = $run->colorize_error("ouch");

Returns the message in the standard error color (bold red).

=item error_output

    $run->error_output;

Outputs any errors.

Calls C<halt>

=item event_globaloptions

Calls any plugin that needs to know

=item subscribe

A plugin can subscribe for an event:

    $run->subscribe(
        print_output => {
            plugin => $self,
            method => "print_output",
        },

=back

=head1 ATTRIBUTES

=over 4

=item spec

Your spec, (App::Spec)

=item options

A hashref with the given options

    {
        verbose => 1,
        foo => 23,
    }

=item parameters

A hashref with the given parameters

=item commands

An arrayref containing all subcommands from the commandline

=item argv_orig

This contains the original contents of C<argv> before processing

=item argv

This is a reference to the commandline arguments array C<@ARGV>, or the
array reference you specified otherwise. When calling your command method,
it will contain the rest of the arguments which weren't processed as
any subcommand, option or parameter.

=item validation_errors

Contains errors from option/parameter validation

=item op

Contains the operation (subroutine) which will be executed to run
yor command

=item cmd

This is an instance of your app class

=item response

This contains the response of your command (exit code, output, ...)

See L<App::Spec::Run::Response>

=item subscribers

Contains a hashref

    {
        print_output => {
            module => $plugin,
            method => 'print_output',
        },
    }

=back

=cut

