# ABSTRACT: Specification for commandline app
use strict;
use warnings;
package App::Spec;
use 5.010;

our $VERSION = '0.000'; # VERSION

use App::Spec::Subcommand;
use App::Spec::Option;
use App::Spec::Parameter;
use List::Util qw/ any /;
use YAML::XS ();
use Storable qw/ dclone /;

use Moo;

has name => ( is => 'rw' );
has appspec => ( is => 'rw' );
has class => ( is => 'rw' );
has title => ( is => 'rw' );
has markup => ( is => 'rw', default => 'pod' );
has options => ( is => 'rw' );
has parameters => ( is => 'rw' );
has subcommands => ( is => 'rw', default => sub { +{} } );
has abstract => ( is => 'rw' );
has description => ( is => 'rw' );

my $DATA = do { local $/; <DATA> };
my $default_spec;

sub build {
    my ($class, %spec) = @_;
    for (@{ $spec{options} || [] }, @{ $spec{parameters} || [] }) {
        $_ = { spec => $_ } unless ref $_;
    }
    $_ = App::Spec::Option->build(%$_) for @{ $spec{options} || [] };
    $_ = App::Spec::Parameter->build(%$_) for @{ $spec{parameters} || [] };
    my $self = $class->new(%spec);
}

sub _read_default_spec {
    $default_spec ||= YAML::XS::Load($DATA);
    return dclone $default_spec;
}

sub runner {
    my ($self) = @_;
    my $class = $self->class;
    my $cmd = $class->new;
    my $run = App::Spec::Run->new({
        spec => $self,
        cmd => $cmd,
    });
    return $run;
}

sub read {
    my ($class, $file) = @_;
    unless (defined $file) {
        die "No filename given";
    }

    my $spec = $class->load_data($file);

    my $has_subcommands = $spec->{subcommands} ? 1 : 0;
    my $default;
    {
        $default = $class->_read_default_spec;

        for my $opt (@{ $default->{options} }) {
            my $name = $opt->{name};
            # TODO
            # this should be moved somewhere else since the name might not
            # be parsed from dsl yet
            no warnings 'uninitialized';
            unless (any { (ref $_ ? $_->{name} : $_) eq $name } @{ $spec->{options} }) {
                push @{ $spec->{options} }, $opt;
            }
        }

        if ($has_subcommands) {
            for my $key (keys %{ $default->{subcommands} } ) {
                my $cmd = $default->{subcommands}->{ $key };
                $spec->{subcommands}->{ $key } ||= $cmd;
            }
        }
    }

    my $commands;
    if ($has_subcommands) {
        # add subcommands to help command
        my $help_subcmds = $spec->{subcommands}->{help}->{subcommands} ||= {};
        $class->_add_subcommands($help_subcmds, $spec->{subcommands}, { subcommand_required => 0 });

        for my $name (keys %{ $spec->{subcommands} || [] }) {
            my $cmd = $spec->{subcommands}->{ $name };
            $commands->{ $name } = App::Spec::Subcommand->build(
                name => $name,
                %$cmd,
            );
        }
    }

    $spec->{subcommands} = $commands;
    my $self = $class->build(%$spec);
    return $self;
}

sub load_data {
    my ($class, $file) = @_;
    my $spec;
    if (ref $file eq 'GLOB') {
        my $data = do { local $/; <$file> };
        $spec = eval { YAML::XS::Load($data) };
    }
    elsif (not ref $file) {
        $spec = eval { YAML::XS::LoadFile($file) };
    }
    elsif (ref $file eq 'SCALAR') {
        my $data = $$file;
        $spec = eval { YAML::XS::Load($data) };
    }
    elsif (ref $file eq 'HASH') {
        $spec = $file;
    }

    unless ($spec) {
        die "Error reading '$file': $@";
    }
    return $spec;
}

sub _add_subcommands {
    my ($self, $commands1, $commands2, $ref) = @_;
    for my $name (keys %{ $commands2 || {} }) {
        next if $name eq "help";
        my $cmd = $commands2->{ $name };
        $commands1->{ $name } = {
            name => $name,
            subcommands => {},
            %$ref,
        };
        my $subcmds = $cmd->{subcommands} || {};
        $self->_add_subcommands($commands1->{ $name }->{subcommands}, $subcmds, $ref);
    }
}

sub has_subcommands {
    my ($self) = @_;
    return $self->subcommands ? 1 : 0;
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

sub generate_pod {
    my ($self) = @_;

    require App::Spec::Pod;
    my $generator = App::Spec::Pod->new(
        spec => $self,
    );
    my $pod = $generator->generate;
    return $pod;

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
        my $completer = App::Spec::Completion::Zsh->new({
            spec => $self,
        });
        return $completer->generate_completion(%args);
    }
    elsif ($shell eq "bash") {
        require App::Spec::Completion::Bash;
        my $completer = App::Spec::Completion::Bash->new({
            spec => $self,
        });
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

=item build

Builds objects out of the hashref

    my $appspec = App::Spec->build(%hash);

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

=item generate_pod

    my $pod = $spec->generate_pod;

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

__DATA__
options:
    -   name: help
        summary: Show command help
        type: flag
        aliases:
        - h
subcommands:
    help:
        op: cmd_help
        summary: Show command help
        subcommand_required: 0
        options:
        -   name: all
            type: flag
    _meta:
        summary: Information and utilities for this app
        subcommands:
            completion:
                summary: Shell completion functions
                subcommands:
                    generate:
                        summary: Generate self completion
                        op: cmd_self_completion
                        options:
                            -   name: name
                                summary: name of the program (optional, override name in spec)
                            -   name: zsh
                                summary: for zsh
                                type: flag
                            -   name: bash
                                summary: for bash
                                type: flag
            pod:
                summary: Pod documentation
                subcommands:
                    generate:
                        summary: Generate self pod
                        op: cmd_self_pod
