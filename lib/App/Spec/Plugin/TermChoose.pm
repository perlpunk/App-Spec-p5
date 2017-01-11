# ABSTRACT: App::Spec Plugin for using Term::Choose
use strict;
use warnings;
package App::Spec::Plugin::TermChoose;
our $VERSION = '0.000'; # VERSION

use Ref::Util qw/ is_arrayref /;

use Moo;
with 'App::Spec::Role::Plugin';


sub init_run {
    my ($self, $run) = @_;
    $run->subscribe(
        validate_argument => {
            plugin => $self,
            method => "validate_argument",
        },
    );
}

sub validate_argument {
    my ($self, %args) = @_;
    my $run = $args{run};
    my $spec = $args{spec};
    my $value = $args{value};
    # TODO only trigger plugin in normal mode
    if (defined $$value) {
        if (
            (is_arrayref($$value) and ($$value->[0] // '') eq '_')
            or $$value eq '_') {

            require Term::Choose;
            my $possible_values = $args{possible_values};
            my @choices = map {
                ref $_ ? $_->{name} .' - ' . $_->{description} : $_
            } @$possible_values;
            my @values = map {
                ref $_ ? $_->{name} : $_
            } @$possible_values;

            my $tc = Term::Choose->new();
            my $prompt = "Select a value for '" . $spec->name . "'\n";

            my @index;
            my %options = (
                layout => 2,
                index => 1,
            );
            if (is_arrayref($$value)) {
                $prompt .= "Select with <Space>, confirm choice with <Enter>, abort with 'q':";
                @index = $tc->choose(
                    \@choices, { prompt => $prompt, %options },
                );
                $$value = [@values[ @index] ];
            }
            else {
                $prompt .= "Confirm choice with <Enter>, abort with 'q':";
                $index[0] = $tc->choose(
                    \@choices, { prompt => $prompt, %options },
                );
                $$value = $values[ $index[0] ];
            }
        }
    }
}

1;

__END__

=pod

=head1 NAME

App::Spec::Plugin::TermChoose - App::Spec Plugin for using Term::Choose

=cut
