use strict;
use warnings;
package App::Spec::Completion::Zsh;

use base 'App::Spec::Completion';

sub generate_completion {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $name = $spec->name;
    my $functions = [];
    my $completion_outer = $self->completion_commands(
        commands => $spec->commands,
        options => $spec->options,
        level => 1,
        functions => $functions,
    );


my $body = <<"EOM";
#compdef $name

_$name() {
    local program=$name
    typeset -A opt_args
    local curcontext="\$curcontext" state line context

$completion_outer
}

@{[ join '', @$functions ]}
EOM
    return $body;
}

sub completion_commands {
    my ($self, %args) = @_;
    my $functions = $args{functions};
    my $spec = $self->spec;
    my $commands = $args{commands};
    my $level = $args{level};
    my $previous = $args{previous} || [];
    my ($opt, $opt_comp) = $self->options(
        options => $args{options},
        level => $level,
        functions => $functions,
        previous => $args{previous},
    );

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
        previous => $args{previous},
    );

    if ($param_args) {
        $arguments .= "$param_args";
    }
    my $default_args = '*: :->args';
    unless (keys %$commands) {
#        $default_args = "*::file:_files";
    }
    $arguments .= $indent2 . "'$default_args' \\\n";
    if ($opt) {
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
                commands => $cmd_spec->subcommands || [],
                options => $cmd_spec->options,
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
        $body .= <<"EOM";
${indent}case \$state in
EOM
    if ($cmds) {
        $body .= <<"EOM";
${indent}cmd$level)
${indent}    $cmds
${indent};;
EOM
    }
        $body .= <<"EOM";
${indent}args)
$subcmds
${indent};;
${indent}*)
$opt_comp
${indent};;
${indent}esac
EOM

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
        $arguments .= $indent . "    '$count: :->$name' \\\n";
        $count++;

        my $completion = '';
        if (ref $p->type) {
            if (my $list = $p->type->{enum}) {
                my @list = map { "'$_'" } @$list;
                $completion = $indent . "        compadd -X '$name:' @list";
            }
        }
        elsif ($p->type eq 'file') {
            $completion = '_files';
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

    my $appname = $self->spec->name;
    my $function_name = "_${appname}_"
        . join ("_", @$previous)
        . "_" . ($p->isa("App::Spec::Option") ? "option" : "param")
        . "_" . $name . "_completion";
    my $function = <<"EOM";
$function_name() \{
    local __dynamic_completion
    IFS=\$'\\n' set -A __dynamic_completion `\$program @args`
    compadd -X "$name:" \$__dynamic_completion
\}
EOM
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

sub options {
    my ($self, %args) = @_;
    my $functions = $args{functions};
    my $spec = $self->spec;
    my $options = $args{options};
    my $level = $args{level};
    my $indent = '        ' x $level;
    my @options;
    my @option_comp;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $desc = $opt->description;
        my $type = $opt->type;
        my $aliases = $opt->aliases;
        my $values = '';
        if (my $def = $opt->completion) {
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
#            push @option_comp, $comp;
        }
        elsif (ref $type) {
            if (my $list = $type->{enum}) {
                my @list = map { qq{"$_"} } @$list;
                $values = ":$name:(@list)";
            }
        }
        elsif ($type eq "file" or $type eq "dir") {
            $values = ":$name:_files";
        }
        elsif (not ref $type and $type ne "bool") {
            $values = ":$name";
        }
        $desc =~ s/['`]/'"'"'/g;
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
        push @options, $indent . "    $str";
    }
    my $option_comp;
    if (@option_comp) {
        $option_comp = <<"EOM";
${indent}    case \$words[\$CURRENT-1] in
@{[ join '', @option_comp ]}
${indent}    esac
EOM
    }
    my $string = join " \\\n", @options;
    return $string, $option_comp;
}


1;
