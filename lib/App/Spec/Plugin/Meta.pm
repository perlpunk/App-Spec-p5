use strict;
use warnings;
package App::Spec::Plugin::Meta;
our $VERSION = '0.000'; # VERSION

use List::Util qw/ any /;

use Moo;
with 'App::Spec::Role::Plugin::Subcommand';

my $yaml = do { local $/; <DATA> };

sub install_subcommands {
    my ($class, %args) = @_;
    my $parent = $args{spec};
    my $appspec = App::Spec::Subcommand->read(\$yaml);
    return $appspec;
}

sub cmd_self_completion {
    my ($self, $run) = @_;
    my $options = $run->options;
    my $shell = $options->{zsh} ? "zsh" : $options->{bash} ? "bash" : '';
    unless ($shell) {
        my $ppid = getppid();
        chomp($shell = `ps --no-headers -o cmd $ppid`);
        $shell =~ s/.*\W(\w*sh).*$/$1/; #handling case of '-zsh' or '/bin/bash'
                                        #or bash -i -rs
    }
    unless (any { $_ eq $shell } qw/ bash zsh / ) {
        die "Specify which shell, '$shell' not supported";
    }
    my $spec = $run->spec;
    my $completion = $spec->generate_completion(
        shell => $shell,
    );
    $run->out($completion);
}

sub cmd_self_pod {
    my ($self, $run) = @_;
    my $spec = $run->spec;
    my $pod = $spec->generate_pod(
    );
    $run->out($pod);
}

1;

__DATA__
---
name: _meta
class: App::Spec::Plugin::Meta
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
