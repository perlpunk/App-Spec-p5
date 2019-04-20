# ABSTRACT: App::Spec Plugin for help subcommand and options
use strict;
use warnings;
package App::Spec::Plugin::Help;
our $VERSION = '0.000'; # VERSION

use Moo;
with 'App::Spec::Role::Plugin::Subcommand';
with 'App::Spec::Role::Plugin::GlobalOptions';

my $yaml;
my $cmd = {
    name => 'help',
    summary => 'Show command help',
    class => 'App::Spec::Plugin::Help',
    op => 'cmd_help',
    subcommand_required => 0,
    options => [
        { spec => 'all' },
    ],
};
my $options  = [
    {
        name => 'help',
        summary => 'Show command help',
        type => 'flag',
        aliases => ['h'],
    },
];

sub install_subcommands {
    my ($class, %args) = @_;
    my $parent = $args{spec};
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
    return $options;
}

sub init_run {
    my ($self, $run) = @_;
    $run->subscribe(
        global_options => {
            plugin => $self,
            method => "global_options",
        },
    );
}

sub global_options {
    my ($self, %args) = @_;
    my $run = $args{run};
    my $options = $run->options;
    my $op;

    if ($run->spec->has_subcommands) {
        if ($options->{help} and (not @{ $run->argv } or $run->argv->[0] ne "help")) {
            # call subcommand 'help'
            unshift @{ $run->argv }, "help";
        }
    }
    else {
        if ($options->{help}) {
            $op = "::cmd_help";
        }
    }

    $run->op("App::Spec::Plugin::Help$op") if $op;
}


1;

=pod

=head1 NAME

App::Spec::Plugin::Help - App::Spec Plugin for help subcommand and options

=head1 DESCRIPTION

This plugin is enabled in L<App::Spec> by default.

This is a plugin which adds C<-h|--help> options to your app.
Also for apps with subcommands it adds a subcommand C<help>.

The help command can then be called with all existing subcommands, like this:

    % app cmd1
    % app cmd2
    % app cmd2 cmd2a
    % app help
    % app help cmd1
    % app help cmd2
    % app help cmd2 cmd2a

=head1 METHODS

=over 4

=item cmd_help

This is the code which is executed when using C<-h|--help> or the subcommand
help.

=item install_options

This method is required by L<App::Spec::Role::Plugin::GlobalOptions>.

See L<App::Spec::Role::Plugin::GlobalOptions#install_options>.

=item install_subcommands

This is required by L<App::Spec::Role::Plugin::Subcommand>.

See L<App::Spec::Role::Plugin::Subcommand#install_subcommands>.

=item global_options

This method is called by L<App::Spec::Run> after global options have been read.

For apps without subcommands it just sets the method to execute to
L<App::Spec::Plugin::Help::cmd_help>.
No further processing is done.

For apps with subcommands it inserts C<help> at the beginning of the
commandline arguments and continues processing.

=item init_run

See L<App::Spec::Plugin>

=back

=cut

