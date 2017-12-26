# ABSTRACT: Specification for commandline app
use strict;
use warnings;
package App::Spec;
use 5.010;

our $VERSION = '0.000'; # VERSION

use App::Spec::Subcommand;
use App::Spec::Option;
use App::Spec::Parameter;
use YAML::XS ();
use Types::Standard qw/Str/;

use Moo;

with('App::Spec::Role::Command');

has title => ( is => 'rw', isa => Str, required => 1 );
has abstract => ( is => 'rw', isa => Str, default => '' );




sub runner {
    my ($self, %args) = @_;
    my $class = $self->class;
    my $cmd = $class->new;
    my $run = App::Spec::Run->new({
        spec => $self,
        cmd => $cmd,
        %args,
    });
    return $run;
}

sub usage {
    my ($self, %args) = @_;
    my $cmds = $args{commands};
    my %highlights = %{ $args{highlights} || {} };
    my $colored = $args{colored} || sub { $_[1] };
    my $appname = $self->name;

    my $abstract = $self->abstract // '';
    my $title = $self->title;
    my ($options, $parameters, $subcmds) = $self->_gather_options_parameters($cmds);
    my $header = $colored->(['bold'], "$appname - $title");
    my $usage = <<"EOM";
$header
$abstract

EOM

    my $body = '';
    my $usage_header = $colored->([qw/ bold /], "Usage:");
    $usage .= "$usage_header $appname";
    $usage .= " @$cmds" if @$cmds;
    if (keys %$subcmds) {
        my $maxlength = 0;
        my @table;
        my $usage_string = "<subcommands>";
        my $header = "Subcommands:";
        if ($highlights{subcommands}) {
            $colored->([qw/ bold red /], $usage_string);
            $colored->([qw/ bold red /], $header);
        }
        else {
            $colored->([qw/ bold /], $header);
        }
        $usage .= " $usage_string";
        $body .= "$header\n";

        my %keys;
        @keys{ keys %$subcmds } = ();
        my @keys;
        if (@$cmds) {
            @keys = sort keys %keys;
        }
        else {
            for my $key (qw/ help _meta /) {
                if (exists $keys{ $key }) {
                    push @keys, $key;
                    delete $keys{ $key };
                }
            }
            unshift @keys, sort keys %keys;
        }
        for my $name (@keys) {
            my $cmd_spec = $subcmds->{ $name };
            my $summary = $cmd_spec->summary;
            push @table, [$name, $summary];
            if (length $name > $maxlength) {
                $maxlength = length $name;
            }
        }
        $body .= $self->_output_table(\@table, [$maxlength]);
    }

    if (@$parameters) {
        my $maxlength = 0;
        my @table;
        my @highlights;
        for my $param (@$parameters) {
            my $name = $param->name;
            my $highlight = $highlights{parameters}->{ $name };
            push @highlights, $highlight ? 1 : 0;
            my $summary = $param->summary;
            my $param_usage_header = $param->to_usage_header;
            if ($highlight) {
                $colored->([qw/ bold red /], $param_usage_header);
            }
            $usage .= " " . $param_usage_header;
            my ($req, $multi) = (' ', '  ');
            if ($param->required) {
                $req = "*";
            }
            if ($param->mapping) {
                $multi = '{}';
            }
            elsif ($param->multiple) {
                $multi = '[]';
            }

            my $flags = $self->_param_flags_string($param);

            push @table, [$name, $req, $multi, $summary . $flags];
            if (length $name > $maxlength) {
                $maxlength = length $name;
            }
        }
        my $parameters_string = $colored->([qw/ bold /], "Parameters:");
        $body .= "$parameters_string\n";
        my @lines = $self->_output_table(\@table, [$maxlength]);
        my $lines = $self->_colorize_lines(\@lines, \@highlights, $colored);
        $body .= $lines;
    }

    if (@$options) {
        my @highlights;
        $usage .= " [options]";
        my $maxlength = 0;
        my @table;
        for my $opt (sort { $a->name cmp $b->name } @$options) {
            my $name = $opt->name;
            my $highlight = $highlights{options}->{ $name };
            push @highlights, $highlight ? 1 : 0;
            my $aliases = $opt->aliases;
            my $summary = $opt->summary;
            my @names = map {
                length $_ > 1 ? "--$_" : "-$_"
            } ($name, @$aliases);
            my $string = "@names";
            if (length $string > $maxlength) {
                $maxlength = length $string;
            }
            my ($req, $multi) = (' ', '  ');
            if ($opt->required) {
                $req = "*";
            }
            if ($opt->mapping) {
                $multi = '{}';
            }
            elsif ($opt->multiple) {
                $multi = '[]';
            }

            my $flags = $self->_param_flags_string($opt);

            push @table, [$string, $req, $multi, $summary . $flags];
        }
        my $options_string = $colored->([qw/ bold /], "Options:");
        $body .= "\n$options_string\n";
        my @lines = $self->_output_table(\@table, [$maxlength]);
        my $lines = $self->_colorize_lines(\@lines, \@highlights, $colored);
        $body .= $lines;
    }

    return "$usage\n\n$body";
}

sub _param_flags_string {
    my ($self, $param) = @_;
    my @flags;
    if ($param->type eq 'flag') {
        push @flags, "flag";
    }
    if ($param->multiple) {
        push @flags, "multiple";
    }
    if ($param->mapping) {
        push @flags, "mapping";
    }
    my $flags = @flags ? " (" . join("; ", @flags) . ")" : '';
    return $flags;
}

sub _colorize_lines {
    my ($self, $lines, $highlights, $colored) = @_;
    my $output = '';
    for my $i (0 .. $#$lines) {
        my $line = $lines->[ $i ];
        if ($highlights->[ $i ]) {
            $colored->([qw/ bold red /], $line);
        }
        $output .= $line;
    }
    return $output;
}

sub _output_table {
    my ($self, $table, $lengths) = @_;
    my @lines;
    my @lengths = map {
        defined $lengths->[$_] ? "%-$lengths->[$_]s" : "%s"
    } 0 .. @{ $table->[0] } - 1;
    for my $row (@$table) {
        no warnings 'uninitialized';
        push @lines, sprintf join('  ', @lengths) . "\n", @$row;
    }
    return wantarray ? @lines : join '', @lines;
}


sub _gather_options_parameters {
    my ($self, $cmds) = @_;
    my @options;
    my @parameters;
    my $global_options = $self->options;
    my $commands = $self->subcommands;
    push @options, @$global_options;

    for my $cmd (@$cmds) {
        my $cmd_spec = $commands->{ $cmd };
        my $options = $cmd_spec->options || [];
        my $parameters = $cmd_spec->parameters || [];
        push @options, @$options;
        push @parameters, @$parameters;

        $commands = $cmd_spec->subcommands || {};

    }
    return \@options, \@parameters, $commands;
}

sub generate_completion {
    my ($self, %args) = @_;
    my $shell = delete $args{shell};

    if ($shell eq "zsh") {
        require App::Spec::Completion::Zsh;
        my $completer = App::Spec::Completion::Zsh->new(
            spec => $self,
        );
        return $completer->generate_completion(%args);
    }
    elsif ($shell eq "bash") {
        require App::Spec::Completion::Bash;
        my $completer = App::Spec::Completion::Bash->new(
            spec => $self,
        );
        return $completer->generate_completion(%args);
    }
}


sub make_getopt {
    my ($self, $options, $result, $specs) = @_;
    my @getopt;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $spec = $name;
        if (my $aliases = $opt->aliases) {
            $spec .= "|$_" for @$aliases;
        }
        unless ($opt->type eq 'flag') {
            $spec .= "=s";
        }
        $specs->{ $name } = $opt;
        if ($opt->multiple) {
            if ($opt->type eq 'flag') {
                $spec .= '+';
            }
            elsif ($opt->mapping) {
                $result->{ $name } = {};
                $spec .= '%';
            }
            else {
                $result->{ $name } = [];
                $spec .= '@';
            }
        }
        push @getopt, $spec, \$result->{ $name },
    }
    return @getopt;
}

=pod

=head1 NAME

App::Spec - Specification for commandline apps

=head1 SYNOPSIS

WARNING: This is still experimental. The spec is subject to change.

This module represents a specification of a command line tool.
Currently it can read the spec from a YAML file or directly from a data
structure in perl.

It uses the role L<App::Spec::Role::Command>.

The L<App::Spec::Run> module is the framework which will run the actual
app.

Have a look at the L<App::Spec::Tutorial> for how to write an app.

In the examples directory you will find the app C<myapp> which is supposed
to demonstrate everything that App::Spec supports right now.

Your script:

    use App::Spec;
    my $spec = App::Spec->read("/path/to/myapp-spec.yaml");

    my $run = $spec->runner;
    $run->run;

    # this is equivalent to
    #my $run = App::Spec::Run->new(
    #    spec => $spec,
    #    cmd => Your::App->new,
    #);
    #$run->run;

Your App class:

    package Your::App;
    use base 'App::Spec::Run::Cmd';

    sub command1 {
        my ($self, $run) = @_;
        my $options = $run->options;
        my $param = $run->parameters;
        # Do something
        $run->out("Hello world!");
        $run->err("oops");
        # you can also use print directly
    }


=head1 METHODS

=over 4

=item read

    my $spec = App::Spec->read("/path/to/myapp-spec.yaml");

=item load_data

Takes a file, hashref or glob and returns generated appspec hashref

    my $hash = $class->load_data($file);

=item new

Constructor.

    my $appspec = App::Spec->new(%hash);

=item runner

Returns an instance of the your app class

    my $run = $spec->runner;
    $run->run;

    # this is equivalent to
    my $run = App::Spec::Example::MyApp->new({
        spec => $spec,
    });
    $run->run;

=item usage

Returns usage output for the specified subcommands:

    my $usage = $spec->usage(
        commands => ["subcommand1","subcommand2"],
    );

=item generate_completion

Generates shell completion script for the spec.

    my $completion = $spec->generate_completion(
        shell => "zsh",
    );

=item make_getopt

Returns options for Getopt::Long

    my @getopt = $spec->make_getopt($global_options, \%options, $option_specs);

=item abstract, appspec, class, description, has_subcommands, markup, name, options, parameters, subcommands, title

Accessors for the things defined in the spec (file)

=back

=head1 SEE ALSO

L<App::AppSpec> - Utilities for App::Spec authors

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

1;

