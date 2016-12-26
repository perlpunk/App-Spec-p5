# ABSTRACT: Main role for App::Spec plugins
use strict;
use warnings;
package App::Spec::Role::Plugin;

use Moo::Role;

sub init_run {
    my ($self, $run) = @_;
}

1;

__END__

=pod

=head1 NAME

App::Spec::Role::Plugin - Main role for App::Spec plugins

=head1 METHODS

=over 4

=item init_run

Will be called with the plugin object/class and an L<App::Spec::Run>
object as parameters.

    my ($self, $run) = @_;

You can then use the C<subscribe> method of App::Spec::Run to subscribe
to certain events.

=back

=cut
