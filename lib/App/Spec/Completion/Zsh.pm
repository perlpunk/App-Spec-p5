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
        commands => $spec->subcommands,
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
        previous => $args{previous},
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
            previous => $args{previous},
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
                commands => $cmd_spec->subcommands || [],
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
    my $command = $def->{command};
    my $op = $def->{op};
    my $appname = $self->spec->name;
    my $function_name = "_${appname}_"
        . join ("_", @$previous)
        . "_" . ($p->isa("App::Spec::Option") ? "option" : "param")
        . "_" . $name . "_completion";

    my $function;
    if ($op) {
        $function = <<"EOM";
$function_name() \{
    local __dynamic_completion
    __dynamic_completion=`PERL5_APPSPECRUN_SHELL=zsh PERL5_APPSPECRUN_COMPLETION_PARAMETER='$name' \$words`
    _alternative "\$__dynamic_completion"
\}
EOM
    }
    elsif ($command) {
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
        my $varname = "__${name}_completion";

        $function = <<"EOM";
$function_name() \{
    local __dynamic_completion
    IFS=\$'\\n' set -A __dynamic_completion `@args`
    compadd -X "$name:" \$__dynamic_completion
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
    for my $key (sort keys %$commands) {
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
        my $desc = $opt->description;
        my $type = $opt->type;
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
        $desc =~ s/\$/\\\$/g;

        my $multiple = $opt->multiple ? "*" : "";
#        '(-c --count)'{-c,--count}'[Number of list items to show]:c' \
#        '(-a --all)'{-a,--all}'[Show all list items]' \
        my @names = map {
            length > 1 ? "--$_" : "-$_"
        } ($name, @$aliases);
        for my $name (@names) {
            my $str = "'$multiple$name\[$desc\]$values'";
            push @options, $indent . "    $str";
        }
    }
    my $string = join " \\\n", @options;
    return $string;
}


1;
