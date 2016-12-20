# ABSTRACT: Plugins for adding options should use this role
use strict;
use warnings;
package App::Spec::Role::Plugin::GlobalOptions;

our $VERSION = '0.000'; # VERSION

use Moo::Role;

requires 'install_options';

1;

__END__

=pod

=head1 NAME

App::Spec::Role::Plugin::GlobalOptions - Plugins for adding options should use this role

=head1 DESCRIPTION

See L<App::Spec::Plugin::Help> for an example.

=head1 REQUIRED METHODS

=over 4

=item install_options

This should return an arrayref of options:

    [
        {
            name => "help",
            summary: "Show command help",
            ...,
        },
    ]



=back
