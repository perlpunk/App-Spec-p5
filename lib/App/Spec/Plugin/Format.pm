# ABSTRACT: App::Spec Plugin for help subcommand and options
use strict;
use warnings;
package App::Spec::Plugin::Format;
our $VERSION = '0.000'; # VERSION

use YAML::XS ();
use Ref::Util qw/ is_arrayref /;

use Moo;
with 'App::Spec::Role::Plugin::GlobalOptions';

my $yaml;
my $options;
sub _read_data {
    unless ($yaml) {
        $yaml = do { local $/; <DATA> };
        ($options) = YAML::XS::Load($yaml);
    }
}


sub install_options {
    my ($class, %args) = @_;
    _read_data();
    return $options;
}

sub event_processed {
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
            $content = YAML::XS::Dump($content);
        }
        elsif ($format eq 'JSON') {
            require JSON::XS;
            my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
            $content = $coder->encode($content) . "\n";
        }
        elsif ($format eq 'Table' and is_arrayref($content)) {
            require Text::Table;
            my $header = shift @$content;
            my $tb = Text::Table->new( @$header );
            $tb->load(@$content);
            $content = "$tb";
        }
        elsif ($format eq 'Data__Dump') {
            require Data::Dump;
            $content = Data::Dump::dump($content) . "\n";
        }
        else {
            $content = Data::Dumper->Dump([$content], ['output']);
        }
        $out->content( $content );
    }

}


1;

=pod

=head1 NAME

App::Spec::Plugin::Format - App::Spec Plugin for help subcommand and options

=head1 DESCRIPTION


=head1 METHODS

=over 4

=item install_options

This method is required by L<App::Spec::Role::Plugin::GlobalOptions>.

See L<App::Spec::Role::Plugin::GlobalOptions#install_options>.

=item event_globaloptions

This method is called by L<App::Spec::Run> after global options have been read.

=item event_processed

This method is called by L<App::Spec::Run> right before output.

=back

=cut

__DATA__
---
-   name: format
    summary: Format output
    type: string
    enum: [JSON, YAML, Table, "Data__Dumper", "Data__Dump"]

