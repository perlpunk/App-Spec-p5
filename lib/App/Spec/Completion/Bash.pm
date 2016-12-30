# ABSTRACT: Shell Completion generator for bash
use strict;
use warnings;
package App::Spec::Completion::Bash;

our $VERSION = '0.000'; # VERSION

use Moo;
extends 'App::Spec::Completion';

sub generate_completion {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;


    my $functions = [];
    my $completion_outer = $self->completion_commands(
        commands => $spec->subcommands,
        options => $spec->options,
        level => 1,
        functions => $functions,
    );

    my $global_options = $spec->options;
    my ($flags_string, $options_string) = $self->flags_options($global_options);
    my $body = <<"EOM";
#!bash

# http://stackoverflow.com/questions/7267185/bash-autocompletion-add-description-for-possible-completions

_$appname() \{

    COMPREPLY=()
    local program=$appname
    local cur=\$\{COMP_WORDS[\$COMP_CWORD]\}
#    echo "COMP_CWORD:\$COMP_CWORD cur:\$cur" >>/tmp/comp
    declare -a FLAGS
    declare -a OPTIONS
    declare -a MYWORDS

    local INDEX=`expr \$COMP_CWORD - 1`
    MYWORDS=("\$\{COMP_WORDS[@]:1:\$COMP_CWORD\}")

    FLAGS=$flags_string
    OPTIONS=$options_string
    __${appname}_handle_options_flags

$completion_outer
\}

_${appname}_compreply() \{
    IFS=\$'\\n' COMPREPLY=(\$(compgen -W "\$1" -- \$\{COMP_WORDS\[COMP_CWORD\]\}))
    if [[ \$\{#COMPREPLY[*]\} -eq 1 ]]; then # Only one completion
        COMPREPLY=( \$\{COMPREPLY[0]%% -- *\} ) # Remove ' -- ' and everything after
        COMPREPLY="\$(echo -e "\$COMPREPLY" | sed -e 's/[[:space:]]*\$//')"
    fi
\}

@{[ join '', @$functions ]}
EOM
    my $static_functions = $self->_functions;

    $body .= <<"EOM";
$static_functions
complete -o default -F _$appname $appname
EOM

    return $body;
}

sub flags_options {
    my ($self, $options) = @_;
    my @flags;
    my @opt;
    for my $o (@$options) {
        my $name = $o->name;
        my $aliases = $o->aliases;
        my $summary = $o->summary;
        my @names = ($name, @$aliases);
        ($summary, @names) = $self->escape_singlequote( $summary, @names );
        @names = map {
            length $_ > 1 ? "--$_" : "-$_"
        } @names;

        my @items = map {
            ("'$_'", "'$summary'")
        } @names;

        if ($o->type eq 'flag') {
            push @flags, @items;
        }
        else {
            push @opt, @items;
        }
    }
    return ("(@flags)", "(@opt)");
}

sub escape_singlequote {
    my ($self, @strings) = @_;
    my @result;
    for my $string (@strings) {
        no warnings 'uninitialized';
        $string =~ s/[']/'"'"'/g;
        push @result, $string;
    }
    return wantarray ? @result : $result[0];
}

sub completion_commands {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $functions = $args{functions};
    my $previous = $args{previous} || [];
    my $commands = $args{commands};
    my $options = $args{options};
    my $level = $args{level};
    my $indent = "    " x $level;

    my @commands = map {
        my $name = $_;
        my $summary = $commands->{ $_ }->summary;
        for ($name, $summary) {
            no warnings 'uninitialized';
            s/['`]/'"'"'/g;
            s/\$/\\\$/g;
        }
        "'$name'" . (length $summary ? q{$'\t'} . "'$summary'" : '')
    } sort grep { not m/^_/ } keys %$commands;
    my $cmds = join q{$'\\n'}, @commands;

    my $index = $level - 1;
    my $subc = <<"EOM";
$indent# subcmds
${indent}case \$\{MYWORDS\[$index\]\} in
EOM

    for my $name (sort keys %$commands) {
        my $cmd_spec = $commands->{ $name };
        my ($flags_string, $options_string) = $self->flags_options($cmd_spec->options);
        $subc .= <<"EOM";
${indent}  $name)
${indent}    FLAGS+=$flags_string
${indent}    OPTIONS+=$options_string
${indent}    __${appname}_handle_options_flags
EOM
        my $subcommands = $cmd_spec->subcommands;
        my $parameters = $cmd_spec->parameters;
        my $cmd_options = $cmd_spec->options;
        if (keys %$subcommands) {
            my $comp = $self->completion_commands(
                commands => $subcommands,
                options => [ @$options, @$cmd_options ],
                level => $level + 1,
                previous => [@$previous, $name],
                functions => $functions,
            );
            $subc .= $comp;
        }
        elsif (@$parameters or @$cmd_options) {
            $subc .= $self->completion_parameters(
                parameters => $parameters,
                options => [ @$options, @$cmd_options ],
                level => $level + 1,
                previous => [@$previous, $name],
                functions => $functions,
            );
        }
        else {
            $subc .= $indent . "    __comp_current_options true || return # no subcmds, no params/opts\n";
        }
        $subc .= <<"EOM";
${indent}  ;;
EOM
    }

    my ($comp_values, $comp_options) = $self->completion_options(
        level => $level,
        options => $options,
        functions => $args{functions},
        previous => $args{previous},
        parameters => [],
    );
    chomp $comp_options;




    $subc .= <<"EOM";
${indent}esac
EOM

    my $completion = <<"EOM";
${indent}case \$INDEX in

${indent}$index)
${indent}    __comp_current_options || return
${indent}    __${appname}_dynamic_comp 'commands' $cmds

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
${indent}  case \$INDEX in
EOM

    for my $i (0 .. $#$parameters) {
        my $param = $parameters->[ $i ];
        my $name = $param->name;
        my $num = $level + $i - 1;
        $comp .= $indent . "  $num)\n";
        $comp .= $indent . "      __comp_current_options || return\n";
        $comp .= $self->completion_parameter(
            parameter => $param,
            level => $level + 1,
            functions => $args{functions},
            previous => $args{previous},
        );
        $comp .= $indent . "  ;;\n";
    }

    if (@$options) {
        my ($comp_values, $comp_options) = $self->completion_options(
            level => $level + 1,
            options => $options,
            functions => $args{functions},
            previous => $args{previous},
            parameters => $parameters,
        );
#        warn __PACKAGE__.':'.__LINE__.": !!!!\n$comp_options\n";
        chomp $comp_options;
        $comp .= <<"EOM";
$indent  *)
${indent}    __comp_current_options true || return # after parameters
${indent}    case \$\{MYWORDS[\$INDEX-1]\} in
$comp_values
${indent}    esac
${indent}    ;;
EOM

    }

    $comp .= $indent . "esac\n";
}

sub completion_options  {
    my ($self, %args) = @_;

    my $appname = $self->spec->name;
    my $options = $args{options};
    my $level = $args{level};
    my $parameters = $args{parameters};
    my $indent = "    " x $level;

    my $comp = '';
    my $num = $level + @$parameters;

    my @comp_options;
    my @comp_values;
    my $comp_value = <<"EOM";
EOM
    my $maxlength = 0;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $aliases = $opt->aliases;
        my @names = ($name, @$aliases);
        for my $n (@names) {
            my $length = length $n;
            $length = $length > 1 ? $length+2 : $length+1;
            $maxlength = $length if $length > $maxlength;
        }
    }
    for my $i (0 .. $#$options) {
        my $opt = $options->[ $i ];
        my $name = $opt->name;
        my $type = $opt->type;
        next if $type eq "flag";
        my $enum = $opt->enum;
        my $summary = $opt->summary;
        $summary =~ s/['`]/'"'"'/g;
        $summary =~ s/\$/\\\$/g;
        my $aliases = $opt->aliases;
        my @names = ($name, @$aliases);
        my @option_strings;
        for my $n (@names) {
            my $dash = length $n > 1 ? "--" : "-";
            my $option_string = "$dash$n";
            push @option_strings, $option_string;
            my $length = length $option_string;
            $option_string .= " " x ($maxlength - $length);
            my $string = length $summary
                ? qq{'$option_string -- $summary'}
                : qq{'$option_string'};
            push @comp_options, $string;
        }

        $comp_value .= <<"EOM";
${indent}  @{[ join '|', @option_strings ]})
EOM
        if ($enum) {
            my @list = map { s/ /\\ /g; $_ } @$enum;
            local $" = q{"$'\\n'"};
            for (@list) {
                s/['`]/'"'"'/g;
                s/\$/\\\$/g;
                $_ = "'$_'";
            }
            $comp_value .= <<"EOM";
${indent}    _${appname}_compreply "@list"
EOM
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

    return ($comp_value, $comp);
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
    if (ref $def) {
        $op = $def->{op};
        $command = $def->{command};
        $command_string = $def->{command_string};
    }
    elsif ($def) {
        my $possible_values = $p->values or die "Error for '$name': completion: 1 but 'values' not defined";
        $op = $possible_values->{op} or die "Error for '$name': 'values' needs an 'op'";
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
    __dynamic_completion=`PERL5_APPSPECRUN_SHELL=bash PERL5_APPSPECRUN_COMPLETION_PARAMETER='$name' \${COMP_WORDS[@]}`
    __${appname}_dynamic_comp '$name' "\$__dynamic_completion"
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
                            my $index = "\$COMP_CWORD";
                            if ($num ne 'CURRENT') {
                                if ($num =~ m/^-/) {
                                    $index .= $num;
                                }
                                else {
                                    $index = $num - 1;
                                }
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
            $string = "@args";
        }
        elsif (defined $command_string) {
            $string = $command_string;
        }
        my $varname = "__${name}_completion";

        chomp $string;
        $function = <<"EOM";
$function_name() \{
    local param_$shell_name=`$string`
    _${appname}_compreply "\$param_$shell_name"
\}
EOM
    }
    push @$functions, $function;
    return $function_name;
}

# sub list_to_alternative {
#     my ($self, %args) = @_;
#     my $list = $args{list};
#     my $maxlength = 0;
#     for (@$list) {
#         if (length($_) > $maxlength) {
#             $maxlength = length $_;
#         }
#     }
#     my @alt = map {
#         my ($alt_name, $summary);
#         if (ref $_ eq 'ARRAY') {
#             ($alt_name, $summary) = @$_;
#         }
#         else {
#             ($alt_name, $summary) = ($_, '');
#         }
#         $summary //= '';
#         $alt_name =~ s/:/\\\\:/g;
#         $summary =~ s/['`]/'"'"'/g;
#         $summary =~ s/\$/\\\$/g;
#         if (length $summary) {
#             $alt_name .= " " x ($maxlength - length($alt_name));
#         }
#         $alt_name;
#     } @$list;
#     return join '', map { "$_\n" } @alt;
# }

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
    my $enum = $param->enum;
    if ($enum) {
        my @list = @$enum;
        local $" = q{"$'\\n'"};
        for (@list) {
            s/['`]/'"'"'/g;
            s/\$/\\\$/g;
        }
        $comp = <<"EOM";
${indent}    _${appname}_compreply "@list"
EOM
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

sub _functions {
    my ($self) = @_;
    my $string = <<'EOM';
__APPNAME_dynamic_comp() {
    local argname="$1"
    local arg="$2"
    local comp name desc cols desclength formatted
    local max=0

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        if [[ "${#name}" -gt "$max" ]]; then
            max="${#name}"
        fi
    done <<< "$arg"

    while read -r line; do
        name="$line"
        desc="$line"
        name="${name%$'\t'*}"
        desc="${desc/*$'\t'}"
        if [[ -n "$desc" && "$desc" != "$name" ]]; then
            # TODO portable?
            cols=`tput cols`
            [[ -z $cols ]] && cols=80
            desclength=`expr $cols - 4 - $max`
            formatted=`printf "'%-*s -- %-*s'" "$max" "$name" "$desclength" "$desc"`
            comp="$comp$formatted"$'\n'
        else
            comp="$comp'$name'"$'\n'
        fi
    done <<< "$arg"
    _APPNAME_compreply "$comp"
}

function __APPNAME_handle_options() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#OPTIONS[@]}; j+=2))
        do
            local option="${OPTIONS[$j]}"
            if [[ "$word" == "$option" ]]; then
                found=1
                i=`expr $i + 1`
                break
            fi
        done
        if [[ -n $found && $i -lt $max ]]; then
            INDEX=`expr $INDEX - 2`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

function __APPNAME_handle_flags() {
    local i j
    declare -a copy
    local last="${MYWORDS[$INDEX]}"
    local max=`expr ${#MYWORDS[@]} - 1`
    for ((i=0; i<$max; i++))
    do
        local word="${MYWORDS[$i]}"
        local found=
        for ((j=0; j<${#FLAGS[@]}; j+=2))
        do
            local flag="${FLAGS[$j]}"
            if [[ "$word" == "$flag" ]]; then
                found=1
                break
            fi
        done
        if [[ -n $found ]]; then
            INDEX=`expr $INDEX - 1`
        else
            copy+=("$word")
        fi
    done
    MYWORDS=("${copy[@]}" "$last")
}

__APPNAME_handle_options_flags() {
    __APPNAME_handle_options
    __APPNAME_handle_flags
}

__comp_current_options() {
    local always="$1"
    if [[ -n $always || ${MYWORDS[$INDEX]} =~ ^- ]]; then

      local options_spec=''
      local j=

      for ((j=0; j<${#FLAGS[@]}; j+=2))
      do
          local name="${FLAGS[$j]}"
          local desc="${FLAGS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done

      for ((j=0; j<${#OPTIONS[@]}; j+=2))
      do
          local name="${OPTIONS[$j]}"
          local desc="${OPTIONS[$j+1]}"
          options_spec+="$name"$'\t'"$desc"$'\n'
      done
      __APPNAME_dynamic_comp 'options' "$options_spec"

      return 1
    else
      return 0
    fi
}

EOM
    my $appname = $self->spec->name;
    $string =~ s/APPNAME/$appname/g;
    return $string;
}

1;

__DATA__

=pod

=head1 NAME

App::Spec::Completion::Bash - Shell Completion generator for bash

See also L<App::Spec::Completion> and L<App::Spec::Completion::Zsh>

=head1 SYNOPSIS

my $completer = App::Spec::Completion::Bash->new( spec => $appspec );

=head1 METHODS

=over 4

=item generate_completion

    my $completion = $completer->generate_completion;

=item completion_commands

=item completion_options

=item completion_parameter

=item completion_parameters

=item dynamic_completion

=item escape_singlequote

    (@names) = $self->escape_singlequote( @names );

=item flags_options

    my ($flags_string, $options_string) = $completer->flags_options($global_options);

=back

=cut
