use strict;
use warnings;
package App::Spec::Completion::Bash;

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
#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_$name() \{

    COMPREPLY=()
    local program=$name
    local cur=\$\{COMP_WORDS[\$COMP_CWORD]\}
#    echo "COMP_CWORD:\$COMP_CWORD cur:\$cur" >>/tmp/comp

$completion_outer
\}

_${name}_compreply() \{
    IFS=\$'\\n' COMPREPLY=(\$(compgen -W "\$1" -- \$\{COMP_WORDS\[COMP_CWORD\]\}))
    if [[ \$\{#COMPREPLY[*]\} -eq 1 ]]; then #Only one completion
        COMPREPLY=( \$\{COMPREPLY[0]%% -- *\} ) #Remove ' -- ' and everything after
    fi
\}

@{[ join '', @$functions ]}

complete -o default -F _$name $name
EOM
    return $body;
}

sub completion_commands {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $name = $spec->name;
    my $functions = $args{functions};
    my $previous = $args{previous} || [];
    my $commands = $args{commands};
    my $level = $args{level};
    my $indent = "    " x $level;

    my @commands = map {
        my $summary = $commands->{ $_ }->summary;
        length $summary ? "$_ -- " . $summary : $_
    } sort keys %$commands;
    for (@commands) {
        s/['`]/'"'"'/g;
        s/\$/\\\$/g;
    }
    my $cmds = join q{'$'\\n''}, @commands;

    my $subc = <<"EOM";
$indent# subcmds
${indent}case \$\{COMP_WORDS\[$level\]\} in
EOM
    for my $name (sort keys %$commands) {
        $subc .= <<"EOM";
${indent}  $name)
EOM
        my $spec = $commands->{ $name };
        my $subcommands = $spec->subcommands;
        my $parameters = $spec->parameters;
        my $options = $spec->options;
        if (keys %$subcommands) {
            my $comp = $self->completion_commands(
                commands => $subcommands,
                options => $spec->options,
                level => $level + 1,
                previous => [@$previous, $name],
                functions => $functions,
            );
            $subc .= $comp;
        }
        elsif (@$parameters or @$options) {
            $subc .= $self->completion_parameters(
                parameters => $parameters,
                options => $options,
                level => $level + 1,
                previous => [@$previous, $name],
                functions => $functions,
            );
        }
        $subc .= <<"EOM";
${indent}  ;;
EOM
    }
    $subc .= <<"EOM";
${indent}esac
EOM

    my $completion = <<"EOM";
${indent}case \$COMP_CWORD in

${indent}$level)
${indent}    _${name}_compreply '$cmds'

${indent};;
${indent}*)
$subc
${indent};;
${indent}esac
EOM
    return $completion;
}

sub completion_parameters {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $parameters = $args{parameters};
    my $options = $args{options};
    my $level = $args{level};
    my $indent = "    " x $level;

    my $comp = <<"EOM";
${indent}case \$COMP_CWORD in
EOM

    for my $i (0 .. $#$parameters) {
        my $param = $parameters->[ $i ];
        my $name = $param->name;
        my $num = $level + $i;
        $comp .= $indent . "$num)\n";
        $comp .= $self->completion_parameter(
            parameter => $param,
            level => $level + 1,
            functions => $args{functions},
            previous => $args{previous},
        );
        $comp .= $indent . ";;\n";
    }

    if (@$options) {
        my $num = $level + @$parameters;
        $comp .= $indent . "*)\n";

        my @comp_options;
        my @comp_values;
        my $comp_value = <<"EOM";
${indent}case \$\{COMP_WORDS[\$COMP_CWORD-1]\} in
EOM
        for my $i (0 .. $#$options) {
            my $opt = $options->[ $i ];
            my $name = $opt->name;
            my $type = $opt->type;
            my $summary = $opt->description;
            my $aliases = $opt->aliases;
            my @names = ($name, @$aliases);
            my @option_strings;
            for my $n (@names) {
                my $dash = length $n > 1 ? "--" : "-";
                my $option_string = "$dash$n";
                $summary =~ s/['`]/'"'"'/g;
                $summary =~ s/\$/\\\$/g;
                my $string = length $summary
                    ? qq{'$option_string -- $summary'}
                    : qq{'$option_string'};
                push @option_strings, $option_string;
                push @comp_options, $string;
            }

            $comp_value .= <<"EOM";
${indent}  @{[ join '|', @option_strings ]})
EOM
            if (ref $type) {
                if (my $list = $type->{enum}) {
                    my @list = map { s/ /\\ /g; "'$_'" } @$list;
                    local $" = q{"$'\\n'"};
                    for (@list) {
                        s/['`]/'"'"'/g;
                        s/\$/\\\$/g;
                    }
                    $comp_value .= <<"EOM";
${indent}    _${appname}_compreply "@list"
EOM
                }
            }
            elsif ($type eq "bool") {
            }
            elsif ($type eq "file" or $type eq "dir") {
            }
            elsif ($opt->completion) {
                my $function_name = $self->dynamic_completion(
                    option => $opt,
                    level => $level,
                    previous => $args{previous},
                    functions => $args{functions},
                );
                $comp_value .= <<"EOM";
${indent}    $function_name
EOM
            }
            $comp_value .= $indent . "  ;;\n";
        }

        {
            local $" = q{"$'\\n'"};
            $comp .= <<"EOM";
$comp_value
${indent}  *)
${indent}    _${appname}_compreply "@comp_options"
${indent}  ;;
${indent}esac
EOM
        }
        $comp .= $indent . ";;\n";
    }

    $comp .= $indent . "esac\n";
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
                    my $index = "\$COMP_CWORD";
                    if ($num ne 'CURRENT') {
                        $index .= $num;
                    }
                    my $string = qq{"\$\{COMP_WORDS\[$index\]\}"};
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

    my $appname = $self->spec->name;
    my $function_name = "_${appname}_"
        . join ("_", @$previous)
        . "_" . ($p->isa("App::Spec::Option") ? "option" : "param")
        . "_" . $name . "_completion";
    my $function = <<"EOM";
$function_name() \{
    local param_$name=`@args`
    _${appname}_compreply "\$param_$name"
\}
EOM
    push @$functions, $function;
    return $function_name;
}

sub completion_parameter {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $param = $args{parameter};
    my $name = $param->name;
    my $level = $args{level};
    my $indent = "    " x $level;

    my $comp = '';

    my $type = $param->type;
    if (ref $type) {
        if (my $list = $type->{enum}) {
            local $" = q{"$'\\n'"};
            for (@$list) {
                s/['`]/'"'"'/g;
                s/\$/\\\$/g;
            }
            $comp = <<"EOM";
${indent}    _${appname}_compreply "@$list"
EOM
        }
    }
    elsif ($type eq "file" or $type eq "dir") {
    }
    elsif ($param->completion) {
        my $function_name = $self->dynamic_completion(
            option => $param,
            level => $level,
            previous => $args{previous},
            functions => $args{functions},
        );
        $comp .= <<"EOM";
${indent}    $function_name
EOM
    }
    return $comp;
}


1;
