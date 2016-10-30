use strict;
use warnings;
package App::Spec::Run::Response;

our $VERSION = '0.000'; # VERSION

use App::Spec::Run::Output;

use Moo;

has exit => ( is => 'rw', default => 0 );
has outputs => ( is => 'rw', default => sub { [] } );
has finished => ( is => 'rw' );
has halted => ( is => 'rw' );

sub add_output {
    my ($self, $out) = @_;
    unless (ref $out) {
        $out = App::Spec::Run::Output->new(
            content => $out,
        );
    }
    my $outputs = $self->outputs;
    push @$outputs, $out;
}

sub add_error {
    my ($self, $out) = @_;
    unless (ref $out) {
        $out = App::Spec::Run::Output->new(
            error => 1,
            content => $out,
        );
    }
    my $outputs = $self->outputs;
    push @$outputs, $out;
}

sub print_output {
    my ($self) = @_;
    my $outputs = $self->outputs;
    for my $out (@$outputs) {
        my $content = $out->content;
        if ($out->error) {
            print STDERR $content;
        }
        else {
            print $content;
        }
    }
}

1;
