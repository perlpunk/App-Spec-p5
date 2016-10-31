# ABSTRACT: Shell Completion generator
use strict;
use warnings;
package App::Spec::Completion;

our $VERSION = '0.000'; # VERSION

use Moo;

has spec => ( is => 'ro' );

1;

__DATA__

=pod

=head1 NAME

App::Spec::Completion - Shell Completion generator

See L<App::Spec::Completion::Bash> and L<App::Spec::Completion::Zsh>

=head1 ATTRIBUTES

=over 4

=item spec

Contains the L<App::Spec> object

=back

=cut
