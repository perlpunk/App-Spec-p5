# ABSTRACT: Represents an App::Spec subcommand
use strict;
use warnings;
package App::Spec::Subcommand;

our $VERSION = '0.000'; # VERSION

use App::Spec::Option;
use App::Spec::Parameter;

use Moo;

with('App::Spec::Role::Command');

has summary => ( is => 'ro' );
has subcommand_required => ( is => 'ro' );

sub default_plugins { }

1;

__END__

=pod

=head1 NAME

App::Spec::Subcommand - Represents an App::Spec subcommand

=head1 METHODS

=over 4

=item default_plugins

Returns an empty list

=back

=head1 ATTRIBUTES

=over 4

=item summary, subcommand_required

Items from the specification.

=back

=cut
