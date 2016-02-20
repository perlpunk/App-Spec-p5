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

my %countries = (
    Austria => {
      Vienna => { weather => "sunny =)", temperature => 23 },
      Salzburg => { weather => "rainy =(", temperature => 13 },
    },
    Germany => {
      Berlin => { weather => "snow =)", temperature => -2 },
      Hamburg => { weather => "sunny =)", temperature => 19 },
      Frankfurt => { weather => "rainy =(", temperature => 23 },
    },
    Netherlands => {
      Amsterdam => { weather => "rainy =(", temperature => 17 },
      Echt => { weather => "sunny =)", temperature => 37 },
    },
);

sub weather {
    my ($self) = @_;
    my $param = $self->parameters;
    my $cities = $param->{city};
    for my $city (@$cities) {
        my $info = $countries{ $param->{country} }->{ $city };
        my $output = sprintf "Weather in %s/%s: %s", $param->{country}, $city, $info->{weather};
        if ($self->options->{temperature}) {
            my $temp = $info->{temperature};
            my $label = "°C";
            if ($self->options->{fahrenheit}) {
              $temp = int($temp * 9 / 5 + 32);
              $label = "F";
            }
            $output .= " (Temperature: $temp$label)";
        }
        say $output;
    }
}

sub countries {
    say for sort keys %countries;
}

sub cities {
    my ($self) = @_;
    my $country = $self->{options}->{country};
    my @countries = @$country ? @$country : sort keys %countries;
    say for map { sort keys %$_ } @countries{ @countries };
}

sub weather_complete {
    my ($self, $args) = @_;
    my $completion = $args->{completion} or return;
    my $comp_param = $completion->{parameter};

    my $param = $self->parameters;
    if ($comp_param eq "city") {
        my $country = $param->{country};
        my $cities = $countries{ $country } or return;
        return [sort keys %$cities];
    }
    elsif ($comp_param eq "country") {
        my @countries = sort keys %countries;
        return \@countries;
    }
    return;
}

sub palindrome{
    my ($self) = @_;
    my $string = $self->parameters->{string};
    say +($string eq reverse $string) ? "yes" : "nope";
}

1;
