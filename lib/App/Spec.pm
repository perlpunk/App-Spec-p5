# ABSTRACT: Specification for commandline app
use strict;
use warnings;
package App::Spec;
use 5.010;

our $VERSION = '0.000'; # VERSION

use App::Spec::Command;
use App::Spec::Option;
use App::Spec::Parameter;
use List::Util qw/ any /;
use YAML::Syck ();

use Moo;

has name => ( is => 'rw' );
has title => ( is => 'rw' );
has options => ( is => 'rw' );
has commands => ( is => 'rw' );

my $DATA = do { local $/; <DATA> };
my $default_spec;

sub _read_default_spec {
    $default_spec ||= YAML::Syck::Load($DATA);
    return $default_spec;
}

sub read {
    my ($class, $file) = @_;
    unless (defined $file) {
        die "No filename given";
    }

    my $spec;
    if (ref $file eq 'GLOB') {
        my $data = do { local $/; <$file> };
        $spec = eval { YAML::Syck::Load($data) };
    }
    elsif (not ref $file) {
        $spec = eval { YAML::Syck::LoadFile($file) };
    }
    elsif (ref $file eq 'HASH') {
        $spec = $file;
    }

    unless ($spec) {
        die "Error reading '$file': $@";
    }

    my $default;
    {
        $default = $class->_read_default_spec;

        for my $opt (@{ $default->{options} }) {
            my $name = $opt->{name};
            unless (any { $_->{name} eq $name } @{ $spec->{options} }) {
                push @{ $spec->{options} }, $opt;
            }
        }

        for my $key (keys %{ $default->{commands} } ) {
            my $cmd = $default->{commands}->{ $key };
            $spec->{commands}->{ $key } ||= $cmd;
        }
    }

    # add subcommands to help command
    my $help_subcmds = $spec->{commands}->{help}->{subcommands} ||= {};
    $class->_add_subcommands($help_subcmds, $spec->{commands});

    my $commands;
    for my $name (keys %{ $spec->{commands} || [] }) {
        my $cmd = $spec->{commands}->{ $name };
        $commands->{ $name } = App::Spec::Command->build({
            name => $name,
            %$cmd,
        });
    }

    my $self = $class->new({
        name => $spec->{name},
        title => $spec->{title},
        options => [map {
            App::Spec::Option->build($_)
        } @{ $spec->{options} || [] }],
        commands => $commands,
    });
    return $self;
}

sub _add_subcommands {
    my ($self, $commands1, $commands2) = @_;
    for my $name (keys %{ $commands2 || {} }) {
        next if $name eq "help";
        my $cmd = $commands2->{ $name };
        $commands1->{ $name } = {
            name => $name,
            subcommands => {},
        };
        my $subcmds = $cmd->{subcommands} || {};
        $self->_add_subcommands($commands1->{ $name }->{subcommands}, $subcmds);
    }
}

sub usage {
    my ($self, $cmds) = @_;
    my $commands = $self->commands;

    my ($options, $parameters) = $self->gather_options_parameters($cmds);
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$options], ['options']);
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$parameters], ['parameters']);
    my $usage = "Usage: @$cmds";
    my $params = '';
    for my $param (@$parameters) {
        my $name = $param->{name};
        $usage .= " <$name>";
        $params .= "$name: $param->{description}";
    }
    $usage .= " [options]\nParameters:\n$params\n";

    for my $opt (@$options) {
        my $name;
        if (ref $opt) {
            $name = $opt->{name};
        }
        else {
            $name = $opt;
        }
    }

    return $usage;
}

sub gather_options_parameters {
    my ($self, $cmds) = @_;
    my @options;
    my @parameters;
    my $global_options = $self->options;
    my $commands = $self->commands;
    push @options, @$global_options;

    for my $cmd (@$cmds) {
        my $cmd_spec = $commands->{ $cmd };
        my $options = $cmd_spec->options || [];
        my $parameters = $cmd_spec->parameters || [];
        push @options, @$options;
        push @parameters, @$parameters;

        $commands = $cmd_spec->subcommands || {};

    }
    return \@options, \@parameters;
}

sub generate_completion {
    my ($self, %args) = @_;
    my $name = $self->name;

    my $completion_outer = $self->zsh_completion_commands(
        commands => $self->commands,
        options => $self->options,
        level => 1,
    );


my $body = <<"EOM";
#compdef $name

_$name() {
    local program=$name
    typeset -A opt_args
    local curcontext="\$curcontext" state line context

$completion_outer
}
EOM
    return $body;
}

sub zsh_completion_commands {
    my ($self, %args) = @_;
    my $commands = $args{commands};
    my $level = $args{level};
    my $previous = $args{previous} || [];
    my $opt = $self->zsh_options(
        options => $args{options},
        level => $level + 1,
    );

    my $indent = '    ' x $level;
    my $indent2 = '        ' x $level;
    my $state = $level > 1 ? "-C" : "";
    my $arguments = $indent2 . "_arguments -s $state \\\n";
    my $cmd_count = $level;
    unless (keys %$commands) {
        $cmd_count--;
    }
    for my $i (1 .. $cmd_count) {
        $arguments .= $indent2 . "    '$i: :->cmd$i' \\\n";
    }

    my ($param_args, $param_case) = $self->zsh_parameters(
        parameters => $args{parameters},
        level => $level + 1,
        count => $level,
    );

    if ($param_args) {
        $arguments .= "$param_args";
    }
    my $default_args = '*: :->args';
    unless (keys %$commands) {
#        $default_args = "*::file:_files";
    }
    $arguments .= $indent2 . "    '$default_args' \\\n";
    if ($opt) {
        $arguments .= "$opt \\\n";
    }
    $arguments .= $indent2 . "&& ret=0\n";

    my $cmds = $self->zsh_commands_alternative(
        commands => $commands,
        level => $level + 1,
    );

    my $subcmds = '';
    if (keys %$commands) {
        $subcmds .= $indent2 . "    case \$line[$level] in\n";
#        $subcmds .= $indent2 . "    case \$words[\$CURRENT-1] in\n";
        for my $key (sort keys %$commands) {
            my $cmd_spec = $commands->{ $key };
            my $name = $cmd_spec->name;
            $subcmds .= $indent . "            $name)\n";
            my $sc = $self->zsh_completion_commands(
                commands => $cmd_spec->subcommands || [],
                options => $cmd_spec->options,
                parameters => $cmd_spec->parameters,
                level => $level + 1,
                previous => [@$previous, $name],
            );
            $subcmds .= $sc;
            $subcmds .= $indent . "        ;;\n";
        }
        $subcmds .= $indent . "    esac\n";
    }

    my $body = <<"EOM";

$indent        # ---- Command: @$previous
$arguments
$param_case
EOM
    if ($cmds) {
        $body .= <<"EOM";
${indent}    case \$state in
${indent}    cmd$level)
${indent}        $cmds
${indent}    ;;
${indent}    args)
$subcmds
${indent}    ;;
${indent}    esac
EOM
    }

    return $body;
}
sub zsh_parameters {
    my ($self, %args) = @_;
    my $parameters = $args{parameters} || [];
    return ('','') unless @$parameters;
    my $level = $args{level};
    my $count = $args{count};
    my $indent = '    ' x $level;

    my $arguments = '';
    my $case = $indent . "case \$state in\n";
    for my $p (@$parameters) {
        my $name = $p->name;
        $arguments .= $indent . "'$count: :->$name' \\\n";
        $count++;

        my $completion = '';
        if ($p->type eq 'file') {
            $completion = '_files';
        }
        elsif ($p->type eq 'user') {
            $completion = '_users';
        }
        elsif ($p->type eq 'host') {
            $completion = '_hosts';
        }
        elsif ($p->completion) {
            my $def = $p->completion;
            my @args;
            for my $arg (@$def) {
                unless (ref $arg) {
                    push @args, "'$arg'";
                    next;
                }
                if (my $replace = $arg->{replace}) {
                    if (ref $replace eq 'ARRAY') {
                        my @repl = @$replace;
                        if ($replace->[0] eq 'SHELL_WORDS') {
                            my $num = $replace->[1];
                            my $index = "\$CURRENT";
                            if ($num ne 'CURRENT') {
                                $index .= $num;
                            }
                            my $string = qq{"\$words\[$index\]"};
                            push @args, $string;
                        }
                    }
                }
            }
            my $varname = "__${name}_completion";
            $completion = <<"EOM";
$indent     local $varname
$indent     IFS=\$'\\n' set -A $varname `\$program @args`
$indent     compadd -X "$name:" \$$varname
EOM
        }
        $case .= <<"EOM";
${indent}        $name)
$completion
${indent}        ;;
EOM
    }
    $case .= $indent . "esac\n";

    return ($arguments, $case);
}

sub zsh_commands_alternative {
    my ($self, %args) = @_;
    my $commands = $args{commands};
    return '' unless keys %$commands;
    my $level = $args{level};
    my @subcommands;
    for my $key (sort keys %$commands) {
        my $cmd = $commands->{ $key };
        my $name = $cmd->name;
        $name =~ s/:/\\\\:/g;
        my $summary = $cmd->summary // '';
        push @subcommands, length $summary ? qq{$name\\:"$summary"} : $name;
    }
    my $string = qq{_alternative 'args:cmd$level:((@subcommands))'};
    return $string;
}

sub zsh_options {
    my ($self, %args) = @_;
    my $options = $args{options};
    my $level = $args{level};
    my @options;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $desc = $opt->description;
        my $type = $opt->type;
        my $aliases = $opt->aliases;
        my $values = '';
        if (ref $type) {
            if (my $enums = $type->{enum}) {
                $values = ":$name:(@$enums)";
            }
        }
        elsif ($type ne "bool") {
            $values = ":$name";
        }
        $desc =~ s/'/'"'"'/g;
#        '(-c --count)'{-c,--count}'[Number of list items to show]:c' \
#        '(-a --all)'{-a,--all}'[Show all list items]' \
        my $name_str;
        if (@$aliases) {
            my @names = map {
                length > 1 ? "--$_" : "-$_"
            } ($name, @$aliases);
            $name_str = "(@names)'\{" . join(',', @names) . "\}'";
        }
        else {
            $name_str = "--$name";
        }
        my $str = "'$name_str\[$desc\]$values'";
        push @options, ("        " x $level) . $str;
    }
    my $string = join " \\\n", @options;
    return $string;
}

sub make_getopt {
    my ($self, $options, $result, $specs) = @_;
    my @getopt;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $spec = $name;
        unless ($opt->type eq 'bool') {
            $spec .= "=s";
        }
        $specs->{ $name } = $opt;
        push @getopt, $spec, \$result->{ $name },
    }
    return @getopt;
}

1;

__DATA__
options:
    -   name: help
        description: Show command help
        type: bool
        aliases:
        - h
commands:
    help:
        op: cmd_help
        summary: Show command help
        options:
        -   name: all
            type: bool
    _complete:
        summary: Generate self completion
        options:
            -   name: name
                description: name of the program
        subcommands:
            zsh:
                op: cmd_self_completion_zsh
                summary: for zsh
            bash:
                op: cmd_self_completion_bash
                summary: for bash
                options:
                    -   name: without-description
                        type: bool
                        default: false
                        description: generate without description
