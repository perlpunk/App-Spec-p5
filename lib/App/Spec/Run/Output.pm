# ABSTRACT: Output class for App::Spec::Run
use strict;
use warnings;
package App::Spec::Run::Output;

our $VERSION = '0.000'; # VERSION

use Moo;
use App::Spec::Types qw(RunOutputType);
use Types::Standard qw(Str Bool);

has type => (
    is => 'rw',
    isa => RunOutputType,
    default => 'plain',
);
has error => (
    is => 'rw',
    isa => Bool,
    default => 0,
);
has content => (
    is => 'rw',
);

1;

__END__

=pod

=head1 NAME

App::Spec::Run::Output - Output class for App::Spec::Run

=head1 ATTRIBUTES

=over 4

=item type

Currently two types ar esupported: C<plain>, C<data>

=item error

If set to 1, output is supposed to go to stderr.

=item content

The text or data content.

=back

=cut
