# ABSTRACT: Plugins for subcommands should use this role
use strict;
use warnings;
package App::Spec::Role::Plugin::Subcommand;

our $VERSION = '0.000'; # VERSION

use Moo::Role;

requires 'install_subcommands';

with 'App::Spec::Role::Plugin';

1;

__END__

=pod

=head1 NAME

App::Spec::Role::Plugin::Subcommand - Plugins for subcommands should use this role

=head1 DESCRIPTION

See L<App::Spec::Plugin::Help> for an example.

=head1 REQUIRED METHODS

=over 4

=item install_subcommands

=back


=cut
