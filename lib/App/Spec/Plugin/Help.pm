use strict;
use warnings;
package App::Spec::Plugin::Help;
use YAML::XS ();

use Moo;
with 'App::Spec::Role::Plugin::Subcommand';
with 'App::Spec::Role::Plugin::GlobalOptions';

my $yaml;
my $cmd;
my $options;
sub read_data {
    unless ($yaml) {
        $yaml = do { local $/; <DATA> };
        ($cmd, $options) = YAML::XS::Load($yaml);
    }
}

sub install_subcommands {
    my ($class, %args) = @_;
    my $parent = $args{spec};
    read_data();
    my $appspec = App::Spec::Subcommand->read($cmd);

    my $help_subcmds = $appspec->subcommands || {};

    my $parent_subcmds = $parent->subcommands || {};
    $class->_add_subcommands($help_subcmds, $parent_subcmds, { subcommand_required => 0 });
    $appspec->subcommands($help_subcmds);

    return $appspec;
}

sub cmd_help {
    my ($self, $run) = @_;
    my $spec = $run->spec;
    my $cmds = $run->commands;
    shift @$cmds;
    my $help = $spec->usage(
        commands => $cmds,
        colored => $run->colorize_code,
    );
    $run->out($help);
}

sub _add_subcommands {
    my ($self, $commands1, $commands2, $ref) = @_;
    for my $name (keys %{ $commands2 || {} }) {
        next if $name eq "help";
        my $cmd = $commands2->{ $name };
        $commands1->{ $name } = App::Spec::Subcommand->new(
            name => $name,
            subcommands => {},
            %$ref,
        );
        my $subcmds = $cmd->{subcommands} || {};
        $self->_add_subcommands($commands1->{ $name }->{subcommands}, $subcmds, $ref);
    }
}

sub install_options {
    my ($class, %args) = @_;
    read_data();
    return $options;
}

1;

__DATA__
---
name: help
summary: Show command help
class: App::Spec::Plugin::Help
op: cmd_help
subcommand_required: 0
options:
    - spec: all
---
-   name: help
    summary: Show command help
    type: flag
    aliases:
      - h

