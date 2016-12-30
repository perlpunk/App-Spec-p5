# ABSTRACT: Response class for App::Spec::Run
use strict;
use warnings;
package App::Spec::Run::Response;

our $VERSION = '0.000'; # VERSION

use App::Spec::Run::Output;
use Scalar::Util qw/ blessed /;

use Moo;
use App::Spec::Types qw(RunOutput ResponseCallbacks);
use Types::Standard qw(Int Bool ArrayRef);

has exit => (
    is => 'rw',
    isa => Int,
    default => 0,
);

has outputs => (
    is => 'rw',
    isa => ArrayRef[RunOutput],
    default => sub { [] },
);

has [qw(finished halted buffered)] => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

has callbacks => (
    is => 'rw',
    isa => ResponseCallbacks,
    default => sub { +{} },
);

sub add_output {
    my ($self, @out) = @_;

    for my $out (@out) {
        unless (blessed $out) {
            $out = App::Spec::Run::Output->new(
                content => $out,
                ref $out ? (type => 'data') : (),
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
    push @$outputs, @out;

    my $callbacks = $self->callbacks->{print_output} || {};
    for my $cb (@$callbacks) {
        $cb->();
    }

    while (my $out = shift @$outputs) {
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

sub add_callbacks {
    my ($self, $event, $cb_add) = @_;
    my $callbacks = $self->callbacks;
    my $cb = $callbacks->{ $event } ||= [];
    push @$cb, @$cb_add;
}

1;

__END__

=pod

=head1 NAME

App::Spec::Run::Response - Response class for App::Spec::Run

=head1 METHODS

=over 4

=item add_output

If you pass it a string, it will create a L<App::Spec::Run::Output>.

    $res->add_output("string\n", "string2\n");
    my $output = App::Spec::Run::Output->new(
        content => "string\n",
    );
    $res->add_output($output);

This will call C<print_output> if buffered is false, otherwise it will
add the output to C<outputs>

=item add_error

Like C<add_output>, but the created Output object will have an attribute
C<error> set to 1.

    $res->add_error("string\n", "string2\n");
    my $output = App::Spec::Run::Output->new(
        error => 1,
        content => "string\n",
    );
    $res->add_error($output);

=item print_output

    $res->print_output(@out);

Prints the given output and all output in C<outputs>.

=item add_callbacks

    $response->add_callbacks(print_output => \@callbacks);

Where C<@callbacks> are coderefs.

=back

=head1 ATTRIBUTES

=over 4

=item buffered

If true, output should be buffered until print_output is called.

Default: false

=item exit

The exit code

=item outputs

Holds an array of L<App::Spec::Run::Output> objects.

=item finished

Set to 1 after print_output has been called.

=item halted

If set to 1, no further processing should be done.

=item callbacks

Contains a hashref of callbacks

    {
        print_output => $coderef,
    },

=back

=cut
