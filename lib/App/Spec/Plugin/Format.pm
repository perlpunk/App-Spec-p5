# ABSTRACT: App::Spec Plugin for formatting data structures
use strict;
use warnings;
package App::Spec::Plugin::Format;
our $VERSION = '0.000'; # VERSION

use YAML::PP;
use Ref::Util qw/ is_arrayref /;
use Encode;

use Moo;
with 'App::Spec::Role::Plugin::GlobalOptions';

my $yaml;
my $options;
sub _read_data {
    unless ($yaml) {
        $yaml = do { local $/; <DATA> };
        ($options) = YAML::PP::Load($yaml);
    }
}


sub install_options {
    my ($class, %args) = @_;
    _read_data();
    return $options;
}

sub init_run {
    my ($self, $run) = @_;
    $run->subscribe(
        print_output => {
            plugin => $self,
            method => "print_output",
        },
    );
}

sub print_output {
    my ($self, %args) = @_;
    my $run = $args{run};
    my $opt = $run->options;
    my $format = $opt->{format} || '';

    my $res = $run->response;
    my $outputs = $res->outputs;
    for my $out (@$outputs) {
        next unless $out->type eq 'data';
        my $content = $out->content;
        if ($format eq 'YAML') {
            $content = encode_utf8 YAML::PP::Dump($content);
        }
        elsif ($format eq 'JSON') {
            require JSON::XS;
            my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
            $content = encode_utf8 $coder->encode($content) . "\n";
        }
        elsif ($format eq 'Table' and is_arrayref($content)) {
            require Text::Table;
            my $header = shift @$content;
            my $tb = Text::Table->new( @$header );
            $tb->load(@$content);
            $content = encode_utf8 "$tb";
        }
        elsif ($format eq 'Data__Dump') {
            require Data::Dump;
            $content = Data::Dump::dump($content) . "\n";
        }
        else {
            $content = Data::Dumper->Dump([$content], ['output']);
        }
        $out->content( $content );
        $out->type( "plain" );
    }

}


1;

=pod

=head1 NAME

App::Spec::Plugin::Format - App::Spec Plugin for formatting data structures

=head1 DESCRIPTION


=head1 METHODS

=over 4

=item install_options

This method is required by L<App::Spec::Role::Plugin::GlobalOptions>.

See L<App::Spec::Role::Plugin::GlobalOptions#install_options>.

=item init_run

See L<App::Spec::Role::Plugin>

=item print_output

This method is called by L<App::Spec::Run> right before output.

=back

=cut

__DATA__
---
-   name: format
    summary: Format output
    type: string
    enum: [JSON, YAML, Table, "Data__Dumper", "Data__Dump"]

