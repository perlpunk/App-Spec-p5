# ABSTRACT: Shell Completion generator for fish
use strict;
use warnings;
package App::Spec::Completion::Fish;

our $VERSION = '0.000'; # VERSION

use Moo;
extends 'App::Spec::Completion';

# prefix for generated helper functions, e.g. __myapp or __lwp_request
has prefix => ( is => 'lazy' );

sub _build_prefix {
    my ($self) = @_;
    return '__' . _ident($self->spec->name);
}

sub generate_completion {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $p = $self->prefix;
    my $appspec_version = App::Spec->VERSION;
    my %state = (
        functions => [],    # generated functions for command completions
        optspecs => {},     # subcommand path => { option name => takes value }
        parents => [],      # subcommand paths which have subcommands
        dynamic => 0,       # true if ${p}_dynamic is needed
    );
    my $lines = $self->completion_commands(
        commands => $spec->subcommands,
        options => $spec->options,
        parameters => $spec->parameters,
        previous => [],
        state => \%state,
    );
    my $optspecs = _optspecs_cases($state{optspecs});
    my $parents = join ' ', map { length($_) ? _quote($_) : "''" } @{ $state{parents} };
    my $dynamic = '';
    if ($state{dynamic}) {
        $dynamic = <<"EOM";

# dynamic completion via App::Spec::Run, prints "value<TAB>description" lines
function ${p}_dynamic
    set -l cmd (commandline -xpc) (commandline -ct)
    PERL5_APPSPECRUN_SHELL=fish PERL5_APPSPECRUN_COMPLETION_PARAMETER=\$argv[1] \$cmd
end
EOM
    }

    return <<"EOM";
# fish completion for $appname
# Generated with perl module App::Spec v$appspec_version
# Requires fish >= 4.0 (uses `commandline -x`)

if string match -qr '^[0-3]\\.' -- \$version
    echo "$appname completion requires fish >= 4.0 (running \$version)" >&2
    return 1
end

# ${p}_optspecs PATH...: argparse optspecs of the options declared by PATH
function ${p}_optspecs
    switch "\$argv"
$optspecs
    end
end

# positional words after the program name, options and their values removed
# like App::Spec::Run: remove the options of the current subcommand level,
# then the next word is the subcommand of the next level
function ${p}_words
    set -l rest (commandline -xpc)
    set -e rest[1]
    set -l words
    # -S (fish >= 4.1): no abbreviated long options, otherwise an unknown -e
    # is taken for e.g. --exists-action; fish 4.0 has no way to turn this off
    set -l strict -S
    string match -q '4.0.*' -- \$version; and set strict
    while true
        set -l specs (${p}_optspecs \$words)
        # a trailing option still waiting for its value makes argparse fail
        argparse \$strict -i \$specs -- \$rest 2>/dev/null
        or argparse \$strict -i \$specs -- \$rest[1..-2] 2>/dev/null
        or return
        set -l positional (string match -v -- '-*' \$argv)
        if not contains -- "\$words" $parents; or not set -q positional[1]
            set -a words \$positional
            break
        end
        set -a words \$positional[1]
        set -e argv[(contains -i -- \$positional[1] \$argv)]
        set rest \$argv
    end
    string join \\n -- \$words
end

# ${p}_using PATH... N|N+
# true if the words are PATH followed by exactly N (N+: at least N) words
function ${p}_using
    set -l n \$argv[-1]
    set -l path \$argv[1..-2]
    set -l words (${p}_words)
    set -l np (count \$path)
    if test \$np -gt 0
        test "\$words[1..\$np]" = "\$path"; or return 1
    end
    set -l rest (math (count \$words) - \$np)
    if string match -q '*+' -- \$n
        test \$rest -ge (string trim -r -c + -- \$n)
    else
        test \$rest -eq \$n
    end
end

# ${p}_prefix PATH...: true if the words start with PATH
function ${p}_prefix
    ${p}_using \$argv 0+
end
$dynamic@{[ join '', @{ $state{functions} } ]}
complete -c @{[ _quote($appname) ]} -f
@{[ join "\n", @$lines ]}
EOM
}

sub completion_commands {
    my ($self, %args) = @_;
    my $commands = $args{commands} || {};
    my $options = $args{options} || [];
    my $parameters = $args{parameters} || [];
    my $previous = $args{previous};
    my $state = $args{state};
    my $appname = _quote($self->spec->name);
    my $p = $self->prefix;
    my @path = map { _quote($_) } @$previous;
    my $using = sub { _quote(join ' ', "${p}_using", @path, @_) };
    my $prefix = _quote(join ' ', "${p}_prefix", @path);
    my @lines;

    for my $key (sort grep { not m/^_/ } keys %$commands) {
        my $cmd = $commands->{ $key };
        push @lines, "complete -c $appname -n " . $using->(0)
            . " -f -a " . _quote($cmd->name) . _desc($cmd->summary);
    }

    for my $i (0 .. $#$parameters) {
        my $param = $parameters->[ $i ];
        my $values = $self->value_args(%args, arg => $param) or next;
        my $n = $param->multiple ? "$i+" : $i;
        push @lines, "complete -c $appname -n " . $using->($n)
            . " $values" . _desc($param->summary);
    }

    my %optspecs;
    for my $opt (@$options) {
        my @names = ($opt->name, @{ $opt->aliases || [] });
        my $type = $opt->type;
        my $takes_value = (not ref $type and $type ne 'flag') ? 1 : 0;
        # argparse rejects duplicate names; value-taking wins
        $optspecs{ $_ } ||= $takes_value for @names;
        my $names = join ' ', map {
            (length > 1 ? "-l " : "-s ") . _quote($_)
        } @names;
        my $line = "complete -c $appname -n $prefix $names" . _desc($opt->summary);
        if ($takes_value) {
            my $values = $self->value_args(%args, arg => $opt);
            # -x: plain -r would offer files for a free-form value
            $line .= $values ? " -r $values" : " -x";
        }
        push @lines, $line;
    }
    $state->{optspecs}->{ "@$previous" } = \%optspecs if %optspecs;
    push @{ $state->{parents} }, "@$previous" if %$commands;

    for my $key (sort keys %$commands) {
        my $cmd = $commands->{ $key };
        push @lines, @{ $self->completion_commands(
            commands => $cmd->subcommands,
            options => $cmd->options,
            parameters => $cmd->parameters,
            previous => [@$previous, $cmd->name],
            state => $state,
        ) };
    }

    return \@lines;
}

# one switch case per subcommand path with options
sub _optspecs_cases {
    my ($optspecs) = @_;
    my @cases;
    for my $path (sort keys %$optspecs) {
        my $specs = $optspecs->{ $path };
        my $list = join ' ', map { $_ . ($specs->{ $_ } ? '=' : '') } sort keys %$specs;
        push @cases, '        case ' . (length $path ? _quote($path) : "''")
            . "\n            string join \\n -- $list";
    }
    return join "\n", @cases;
}

# returns complete(1) flags for the possible values of an option or parameter
sub value_args {
    my ($self, %args) = @_;
    my $arg = $args{arg};
    my $type = $arg->type;
    if (my $enum = $arg->enum) {
        return '-f -a ' . _quote_list(map { _quote($_) } @$enum);
    }
    elsif ($type =~ m/^file(name)?\z/) {
        return '-F';
    }
    elsif ($type =~ m/^dir(name)?\z/) {
        return q{-f -a '(__fish_complete_directories (commandline -ct))'};
    }
    elsif ($type eq 'user') {
        return q{-f -a '(__fish_complete_users)'};
    }
    elsif ($type eq 'host') {
        return q{-f -a '(__fish_print_hostnames)'};
    }
    elsif ($arg->completion) {
        return '-f -a ' . _quote('(' . $self->dynamic_completion(%args) . ')');
    }
    return '';
}

# returns the call for dynamic completion, generating a function if needed
sub dynamic_completion {
    my ($self, %args) = @_;
    my $arg = $args{arg};
    my $name = $arg->name;

    my $def = $arg->completion;
    my ($op, $command, $command_string);
    if (not ref $def and $def == 1) {
        my $possible_values = $arg->values or die "Error for '$name': completion: 1 but 'values' not defined";
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

    if ($op) {
        $args{state}->{dynamic} = 1;
        return $self->prefix . '_dynamic ' . _quote($name);
    }

    my $function_name = join '_', $self->prefix, (map { _ident($_) } @{ $args{previous} }),
        ($arg->isa("App::Spec::Option") ? "option" : "param"),
        _ident($name), "completion";

    my $run;
    if ($command) {
        my @words;
        for my $word (@$command) {
            unless (ref $word) {
                push @words, _quote($word);
                next;
            }
            my $replace = $word->{replace} or next;
            if (ref $replace eq 'ARRAY') {
                next unless $replace->[0] eq 'SHELL_WORDS';
                my $num = $replace->[1];
                # same indexing as zsh $words[$CURRENT...], CURRENT is the last word
                my $index = $num eq 'CURRENT' ? -1
                    : $num =~ m/^-(\d+)\z/ ? -($1 + 1)
                    : $num;
                push @words, "\$words[$index]";
            }
            elsif ($replace eq 'SELF') {
                push @words, '$words[1]';
            }
        }
        $run = "@words";
    }
    elsif (defined $command_string) {
        # command_string is bash code in existing specs
        $run = 'CURRENT_WORD=$words[-1] bash -c ' . _quote($command_string);
    }
    else {
        die "Error for '$name': 'completion' needs 'op', 'command' or 'command_string'";
    }

    push @{ $args{state}->{functions} }, <<"EOM";

function $function_name
    set -l words (commandline -xpc) (commandline -ct)
    $run
end
EOM
    return $function_name;
}

# " -d 'summary'" or nothing for an empty summary
sub _desc {
    my ($summary) = @_;
    $summary //= '';
    $summary =~ s/\s+/ /g;
    $summary =~ s/^ | \z//g;
    return length $summary ? " -d " . _quote($summary) : '';
}

# fish identifier part, e.g. lwp-request => lwp_request
sub _ident {
    my ($name) = @_;
    $name =~ tr/A-Za-z0-9_/_/c;
    return $name;
}

# fish single quoted string, bare word if no quoting is needed
sub _quote {
    my ($string) = @_;
    return $string if $string =~ m{\A[A-Za-z0-9_.,:+/@][A-Za-z0-9_.,:+/@-]*\z};
    $string =~ s/([\\'])/\\$1/g;
    return "'$string'";
}

# quoted list of already quoted words:
# "'almond milk' 'soy milk'" reads better than '\'almond milk\' \'soy milk\''
sub _quote_list {
    my $list = join ' ', @_;
    return _quote($list) unless $list =~ m/'/;
    $list =~ s/([\\"\$])/\\$1/g;
    return qq{"$list"};
}

1;

__DATA__

=pod

=head1 NAME

App::Spec::Completion::Fish - Shell Completion generator for fish

See also L<App::Spec::Completion>, L<App::Spec::Completion::Bash> and
L<App::Spec::Completion::Zsh>

=head1 SYNOPSIS

    my $completer = App::Spec::Completion::Fish->new( spec => $appspec );

=head1 REQUIREMENTS

The generated script requires B<fish 4.0> or newer, because it uses
C<commandline -x>. On older fish versions it prints an error and returns.
On fish 4.0, long options can be abbreviated, so an unknown option can be
taken for an abbreviation of a known one (fish 4.1 adds C<argparse --strict-longopts>).

=head1 METHODS

=over 4

=item generate_completion

    my $completion = $completer->generate_completion;

=item completion_commands

Recursively generates C<complete> lines for commands, parameters and options,
and collects the options valid for each subcommand path.

=item value_args

Returns C<complete> flags for the possible values of an option or parameter.

=item dynamic_completion

Returns the function (call) for dynamic completion and adds generated
functions for C<command> and C<command_string>.

=back

=cut
