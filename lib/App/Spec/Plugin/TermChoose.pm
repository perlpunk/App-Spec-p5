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
    if (defined $$value) {
        if (
            (is_arrayref($$value) and ($$value->[0] // '') eq '_')
            or $$value eq '_') {
            require Term::Choose;
            my $possible_values = $args{possible_values};
            @$possible_values = map { ref $_ ? $_->{name} : $_ } @$possible_values;
            my $tc = Term::Choose->new();
            my $list = [qw/ tea coffee /, 1..10];
            my $choice = $tc->choose( $possible_values );
            $$value = is_arrayref($$value) ? [$choice] : $choice;
        }
    }
}

1;

__END__

=pod

=head1 NAME

App::Spec::Plugin::TermChoose - App::Spec Plugin for using Term::Choose

=cut
