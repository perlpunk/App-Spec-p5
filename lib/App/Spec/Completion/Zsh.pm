# ABSTRACT: Shell Completion generator for zsh
use strict;
use warnings;
package App::Spec::Completion::Zsh;

our $VERSION = '0.000'; # VERSION

use Moo;
extends 'App::Spec::Completion';

sub generate_completion {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $functions = [];
    my $appspec_version = App::Spec->VERSION;
    my $completion_outer = $self->completion_commands(
        commands => $spec->subcommands,
        options => $spec->options,
        parameters => $spec->parameters,
        level => 1,
        functions => $functions,
    );


my $body = <<"EOM";
#compdef $appname

# Generated with perl module App::Spec v$appspec_version

_$appname() {
    local program=$appname
    typeset -A opt_args
    local curcontext="\$curcontext" state line context

$completion_outer
}

@{[ join '', @$functions ]}
__${appname}_dynamic_comp() {
EOM
    $body .= <<'EOM';
    local argname="$1"
    local arg="$2"
    local comp="arg:$argname:(("
    local line
    while read -r line; do
        local name="$line"
        local desc="$line"
        name="${name%$'\t'*}"
        desc="${desc/*$'\t'}"
        comp="$comp$name"
        if [[ -n "$desc" && "$name" != "$desc" ]]; then
            comp="$comp\\:"'"'"$desc"'"'
        fi
        comp="$comp "
    done <<< "$arg"

    comp="$comp))"
    _alternative "$comp"
}
EOM

    return $body;
}

sub completion_commands {
    my ($self, %args) = @_;
    my $functions = $args{functions};
    my $spec = $self->spec;
    my $commands = $args{commands};
    my $options = $args{options};
    my $level = $args{level};
    my $previous = $args{previous} || [];

    my $indent = '        ' x $level;
    my $indent2 = '        ' x $level . '    ';
    my $state = $level > 1 ? "-C" : "";
    my $arguments = $indent . "_arguments -s $state \\\n";
    my $cmd_count = $level;
    unless (keys %$commands) {
        $cmd_count--;
    }
    for my $i (1 .. $cmd_count) {
        $arguments .= $indent2 . "'$i: :->cmd$i' \\\n";
    }

    my ($param_args, $param_case) = $self->parameters(
        parameters => $args{parameters},
        level => $level,
        count => $level,
        functions => $functions,
        previous => $previous,
    );

    if ($param_args) {
        $arguments .= "$param_args";
    }
    if (keys %$commands) {
        $arguments .= $indent2 . "'*: :->args' \\\n";
    }

    if (@$options and not keys %$commands) {
        my ($opt) = $self->options(
            options => $options,
            level => $level,
            functions => $functions,
            previous => $previous,
        );
        $arguments .= "$opt \\\n";
    }
    $arguments .= $indent2 . "&& ret=0\n";

    my $cmds = $self->commands_alternative(
        commands => $commands,
        level => $level + 1,
    );

    my $subcmds = '';
    if (keys %$commands) {
        $subcmds .= $indent2 . "case \$line[$level] in\n";
        for my $key (sort keys %$commands) {
            my $cmd_spec = $commands->{ $key };
            my $name = $cmd_spec->name;
            $subcmds .= $indent2 . "$name)\n";
            my $sc = $self->completion_commands(
                commands => $cmd_spec->subcommands || {},
                options => [ @$options, @{ $cmd_spec->options } ],
                parameters => $cmd_spec->parameters,
                level => $level + 1,
                previous => [@$previous, $name],
                functions => $functions,
            );
            $subcmds .= $sc;
            $subcmds .= $indent2 . ";;\n";
        }
        $subcmds .= $indent2 . "esac\n";
    }

    my $body = <<"EOM";

$indent# ---- Command: @$previous
$arguments
$param_case
EOM
    my $cmd_state = '';
    if ($cmds) {
        $cmd_state = <<"EOM";
${indent}cmd$level)
${indent}    $cmds
${indent};;
EOM
    }

    my $subcmd_state = '';
    if (keys %$commands) {
        $subcmd_state = <<"EOM";
${indent}args)
$subcmds
${indent};;
EOM
    }

    if ($cmd_state or $subcmd_state) {
        $body .= <<"EOM";
${indent}case \$state in
EOM

        $body .= <<"EOM";
$cmd_state
$subcmd_state
${indent}esac
EOM
    }

    return $body;
}

sub parameters {
    my ($self, %args) = @_;
    my $functions = $args{functions};
    my $spec = $self->spec;
    my $parameters = $args{parameters} || [];
    return ('','') unless @$parameters;
    my $level = $args{level};
    my $count = $args{count};
    my $indent = '        ' x $level;

    my $arguments = '';
    my $case = $indent . "case \$state in\n";
    for my $p (@$parameters) {
        my $name = $p->name;
        my $num = $count;
        if ($p->multiple) {
            $num = "*";
        }
        $arguments .= $indent . "    '$num: :->$name' \\\n";
        $count++;

        my $completion = '';
        if (my $enum = $p->enum) {
            my @list = map { "'$_'" } @$enum;
            $completion = $indent . "        compadd -X '$name:' @list";
        }
        elsif ($p->type =~ m/^file(name)?\z/) {
            $completion = '_files';
        }
        elsif ($p->type =~ m/^dir(name)?\z/) {
            $completion = '_path_files -/';
        }
        elsif ($p->type eq 'user') {
            $completion = '_users';
        }
        elsif ($p->type eq 'host') {
            $completion = '_hosts';
        }
        elsif ($p->completion) {
            $completion = $self->dynamic_completion(
                option => $p,
                level => $level,
                functions => $functions,
                previous => $args{previous},
            );
        }
        $case .= <<"EOM";
${indent}$name)
$completion
${indent};;
EOM
    }
    $case .= $indent . "esac\n";

    return ($arguments, $case);
}

sub dynamic_completion {
    my ($self, %args) = @_;
    my $functions = $args{functions};
    my $previous = $args{previous};
    my $p = $args{option};
    my $level = $args{level};
    my $indent = '        ' x $level;
    my $name = $p->name;
    my $shell_name = $name;
    $name =~ tr/^A-Za-z0-9_:-/_/c;
    $shell_name =~ tr/^A-Za-z0-9_/_/c;

    my $def = $p->completion;
    my ($op, $command, $command_string);
    if (not ref $def and $def == 1) {
        my $possible_values = $p->values or die "Error for '$name': completion: 1 but 'values' not defined";
        $op = $possible_values->{op} or die "Error for '$name': 'values' needs an 'op'";
    }
    elsif (ref $def) {
        $op = $def->{op};
        $command = $def->{command};
        $command_string = $def->{command_string};
    }
    else {
        die "Error for '$name': invalid value for 'completion'";
    }

    my $appname = $self->spec->name;
    my $function_name = "_${appname}_"
        . join ("_", @$previous)
        . "_" . ($p->isa("App::Spec::Option") ? "option" : "param")
        . "_" . $shell_name . "_completion";

    my $function;
    if ($op) {
        $function = <<"EOM";
$function_name() \{
    local __dynamic_completion
    __dynamic_completion=\$(PERL5_APPSPECRUN_SHELL=zsh PERL5_APPSPECRUN_COMPLETION_PARAMETER='$name' "\${words[@]}")
    __${appname}_dynamic_comp '$name' \$__dynamic_completion
\}
EOM
    }
    elsif ($command or $command_string) {
        my $string = '';

        if ($command) {
            my @args;
            for my $arg (@$command) {
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
                                if ($num =~ m/^-/) {
                                    $index .= $num;
                                }
                                else {
                                    $index = $num;
                                }
                            }
                            my $string = qq{"\$words\[$index\]"};
                            push @args, $string;
                        }
                    }
                    else {
                        if ($replace eq "SELF") {
                            push @args, "\$program";
                        }
                    }
                }
            }
            $string = "@args";
        }
        elsif (defined $command_string) {
            $string = $command_string;
        }
        my $varname = "__${name}_completion";

        $function = <<"EOM";
$function_name() \{
    local __dynamic_completion
    local CURRENT_WORD="\$words\[CURRENT\]"
    IFS=\$'\\n' __dynamic_completion=( \$( \n$string\n ) )
    compadd -X "$shell_name:" \$__dynamic_completion
\}
EOM
}
    push @$functions, $function;
    return $function_name;
}

sub commands_alternative {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $commands = $args{commands};
    return '' unless keys %$commands;
    my $level = $args{level};
    my @subcommands;
    for my $key (sort grep { not m/^_/ } keys %$commands) {
        my $cmd = $commands->{ $key };
        my $name = $cmd->name;
        my $summary = $cmd->summary;
        push @subcommands, [$name, $summary];
    }
    my $string = $self->list_to_alternative(
        name => "cmd$level",
        list => \@subcommands,
    );
    return "_alternative '$string'";
}

sub list_to_alternative {
    my ($self, %args) = @_;
    my $list = $args{list};
    my $name = $args{name};
    my @alt = map {
        my ($alt_name, $summary);
        if (ref $_ eq 'ARRAY') {
            ($alt_name, $summary) = @$_;
            $summary //= '';
        }
        else {
            ($alt_name, $summary) = ($_, '');
        }
        $alt_name =~ s/:/\\\\:/g;
        $summary =~ s/"/\\"/g;
        $summary =~ s/['`]/'"'"'/g;
        $summary =~ s/\$/\\\$/g;
        length $summary ? qq{$alt_name\\:"$summary"} : $alt_name
    } @$list;
    my $string = qq{args:$name:((@alt))};
}

sub options {
    my ($self, %args) = @_;
    my $functions = $args{functions};
    my $spec = $self->spec;
    my $options = $args{options};
    my $level = $args{level};
    my $indent = '        ' x $level;
    my @options;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $summary = $opt->summary;
        my $type = $opt->type;
        my $enum = $opt->enum;
        my $aliases = $opt->aliases;
        my $values = '';
        if ($opt->completion) {
            my @names = map {
                length > 1 ? "--$_" : "-$_"
            } ($name, @$aliases);
            my $comp = $indent . join ('|', @names) . ")\n";
            my $function_name = $self->dynamic_completion(
                option => $opt,
                level => $level,
                functions => $functions,
                previous => $args{previous},
            );
            $values = ":$name:$function_name";
            $comp .= $indent . ";;\n";
        }
        elsif ($enum) {
            my @list = map {
                my $item = $_;
                $item =~ s/:/\\:/g;
                qq{"$item"};
            } @$enum;
            $values = ":$name:(@list)";
        }
        elsif ($type =~ m/^file(name)?\z/) {
            $values = ":$name:_files";
        }
        elsif ($type =~ m/^dir(name)?\z/) {
            $values = ":$name:_path_files -/";
        }
        elsif (not ref $type and $type ne "flag") {
            $values = ":$name";
        }
        $summary =~ s/['`]/'"'"'/g;
        $summary =~ s/\$/\\\$/g;

        my $multiple = $opt->multiple ? "*" : "";
#        '(-c --count)'{-c,--count}'[Number of list items to show]:c' \
#        '(-a --all)'{-a,--all}'[Show all list items]' \
        my @names = map {
            length > 1 ? "--$_" : "-$_"
        } ($name, @$aliases);
        for my $name (@names) {
            my $str = "'$multiple$name\[$summary\]$values'";
            push @options, $indent . "    $str";
        }
    }
    my $string = join " \\\n", @options;
    return $string;
}


1;

__DATA__

=pod

=head1 NAME

App::Spec::Completion::Zsh - Shell Completion generator for zsh

See also L<App::Spec::Completion> and L<App::Spec::Completion::Zsh>

=head1 SYNOPSIS

my $completer = App::Spec::Completion::Zsh->new( spec => $appspec );

=head1 METHODS

=over 4

=item generate_completion

    my $completion = $completer->generate_completion;

=item commands_alternative

=item completion_commands

=item dynamic_completion

=item list_to_alternative

=item options

=item parameters

=back

=cut
