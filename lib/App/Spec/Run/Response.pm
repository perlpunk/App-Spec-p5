use strict;
use warnings;
package App::Spec::Run::Response;

our $VERSION = '0.000'; # VERSION

use App::Spec::Run::Output;
use Scalar::Util qw/ blessed /;

use Moo;

has exit => ( is => 'rw', default => 0 );
has outputs => ( is => 'rw', default => sub { [] } );
has finished => ( is => 'rw' );
has halted => ( is => 'rw' );
has buffered => ( is => 'rw', default => 0 );

sub add_output {
    my ($self, @out) = @_;

    for my $out (@out) {
        unless (blessed $out) {
            $out = App::Spec::Run::Output->new(
                content => $out,
            );
        }
    }

    if ($self->buffered) {
        my $outputs = $self->outputs;
        push @$outputs, @out;
    }
    else {
        $self->print_output(@out);
    }
}

sub add_error {
    my ($self, @out) = @_;

    for my $out (@out) {
        unless (blessed $out) {
            $out = App::Spec::Run::Output->new(
                error => 1,
                content => $out,
            );
        }
    }

    if ($self->buffered) {
        my $outputs = $self->outputs;
        push @$outputs, @out;
    }
    else {
        $self->print_output(@out);
    }
}

sub print_output {
    my ($self, @out) = @_;
    my $outputs = $self->outputs;
    for my $out (@$outputs, @out) {
        my $content = $out->content;
        if (ref $content) {
            require Data::Dumper;
            $content = Data::Dumper->Dump([$content], ['output']);
        }
        if ($out->error) {
            print STDERR $content;
        }
        else {
            print $content;
        }
    }
}

1;
