use strict;
use warnings;
package App::Spec::Completion::Zsh;

use base 'App::Spec::Completion';

sub generate_completion {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $name = $spec->name;
    my $completion_outer = $self->completion_commands(
        commands => $spec->commands,
        options => $spec->options,
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

sub completion_commands {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $commands = $args{commands};
    my $level = $args{level};
    my $previous = $args{previous} || [];
    my $opt = $self->options(
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

    my ($param_args, $param_case) = $self->parameters(
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

    my $cmds = $self->commands_alternative(
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
            my $sc = $self->completion_commands(
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

sub parameters {
    my ($self, %args) = @_;
    my $spec = $self->spec;
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
        if (ref $p->type) {
            if (my $list = $p->type->{enum}) {
                my @list = map { "'$_'" } @$list;
                $completion = "compadd -X '$name:' @list";
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
    my $spec = $self->spec;
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
            if (my $list = $type->{enum}) {
                my @list = map { qq{"$_"} } @$list;
                $values = ":$name:(@list)";
            }
        }
        elsif ($type ne "bool") {
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
        push @options, ("        " x $level) . $str;
    }
    my $string = join " \\\n", @options;
    return $string;
}


1;
