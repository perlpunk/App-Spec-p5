package App::Spec::Example::MyApp;
use warnings;
use strict;
use 5.010;

use base 'App::Spec::Run';

sub cook {
    my ($self) = @_;
    my $param = $self->parameters;
    my $opt = $self->options;

    my @with;
    my $with = $opt->{with} // '';
    if ($with eq "cow milk") {
        die "Sorry, no cow milk today. go vegan\n";
    }
    push @with, $with if $with;
    push @with, "sugar" if $opt->{sugar};

    say "Starting to cook $param->{drink}"
    . (@with ? " with ". (join " and ", @with) : '');
}

sub weather {
    my ($self) = @_;
    my $param = $self->parameters;
    my $country = $param->{country};
    my $cities = $param->{city};
    for my $city (@$cities) {
        say "It's rainy in $country/$city =(";
    }
}

my %countries = (
    Austria => [qw/ Vienna Salzburg /],
    Germany => [qw/ Berlin Hamburg Frankfurt /],
    Netherlands => [qw/ Amsterdam Echt /],
);

sub countries {
    say for sort keys %countries;
}

sub cities {
    my ($self) = @_;
    my $country = $self->{options}->{country};
    my @countries = @$country ? @$country : sort keys %countries;
    say for map { sort @$_ } @countries{ @countries };
}

1;
