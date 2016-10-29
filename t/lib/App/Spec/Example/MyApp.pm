package App::Spec::Example::MyApp;
use warnings;
use strict;
use 5.010;

use Ref::Util qw/ is_arrayref is_hashref /;

use base 'App::Spec::Run::Cmd';

sub _dump_hash {
    my ($self, $hash) = @_;
    my @strings;
    for my $key (sort keys %$hash) {
        next unless defined $hash->{ $key };
        my $value = $hash->{ $key };
        if (is_hashref($value)) {
            for my $key2 (sort keys %$value) {
                push @strings, "$key=($key2=$value->{ $key2 })";
            }
        }
        else {
            push @strings, "$key=$value";
        }
    }
    return join ",", @strings;
}

sub cook {
    my ($self, $run) = @_;
    my $param = $run->parameters;
    my $opt = $run->options;
    if ($ENV{PERL5_APPSPECRUN_TEST}) {
        $run->out("Subcommands: cook");
        $run->out("Options: " . $self->_dump_hash($opt));
        $run->out("Parameters: " .  $self->_dump_hash($param));
        return;
    }

    my @with;
    my $with = $opt->{with} // '';
    if ($with eq "cow milk") {
        die "Sorry, no cow milk today. go vegan\n";
    }
    push @with, $with if $with;
    push @with, "sugar" if $opt->{sugar};

    $run->out("Starting to cook $param->{drink}"
    . (@with ? " with ". (join " and ", @with) : ''));
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
    my ($self, $run) = @_;
    my $param = $run->parameters;
    my $cities = $param->{city};
    for my $city (@$cities) {
        my $info = $countries{ $param->{country} }->{ $city };
        my $output = sprintf "Weather in %s/%s: %s", $param->{country}, $city, $info->{weather};
        if ($run->options->{temperature}) {
            my $temp = $info->{temperature};
            my $label = "°C";
            if ($run->options->{fahrenheit}) {
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
    my ($self, $run) = @_;
    my $country = $run->options->{country};
    my @countries = @$country ? @$country : sort keys %countries;
    say for map { sort keys %$_ } @countries{ @countries };
}

sub weather_complete {
    my ($self, $run, $args) = @_;
    my $runmode = $args->{runmode};
    return if $runmode ne "completion";
    my $comp_param = $args->{parameter};

    my $param = $run->parameters;
    if ($comp_param eq "city") {
        my $country = $param->{country};
        my $cities = $countries{ $country } or return;
        return [map { +{ name => $_, description => "$_ ($country)" } } sort keys %$cities];
    }
    elsif ($comp_param eq "country") {
        my @countries = sort keys %countries;
        return \@countries;
    }
    return;
}

sub palindrome{
    my ($self, $run) = @_;
    my $string = $run->parameters->{string};
    say +($string eq reverse $string) ? "yes" : "nope";
}

my %units = (
    temperature => {
        celsius => { label => "°C" },
        kelvin => { label => "K" },
        fahrenheit => { label => "°F" },
    },
    distance => {
        meter => { label => "m" },
        inch => { label => "in" },
        foot => { label => "ft" },
    },
);

use constant KELVIN => 273.15;
sub celsius_fahrenheit { $_[0] * 9 / 5 + 32 }
sub fahrenheit_celsius { ($_[0] - 32) / (9 / 5) }
sub meter_inch { $_[0] * 39.37 }
sub inch_meter { $_[0] / 39.37 }
sub meter_foot { $_[0] * 3.28083 }
sub foot_meter { $_[0] / 3.28083 }
sub inch_foot { $_[0] / 12 }
sub foot_inch { $_[0] * 12 }
my %conversions = (
    temperature => {
        celsius_fahrenheit => sub {
            return sprintf "%.2f", celsius_fahrenheit($_[0])
        },
        celsius_kelvin => sub {
            return sprintf "%.2f", ($_[0] + KELVIN);
        },
        fahrenheit_celsius => sub {
            return sprintf "%.2f", fahrenheit_celsius($_[0])
        },
        fahrenheit_kelvin => sub {
            return sprintf "%.2f", fahrenheit_celsius($_[0]) + KELVIN
        },
        kelvin_celsius => sub {
            return sprintf "%.2f", $_[0] - KELVIN
        },
        kelvin_fahrenheit => sub {
            return sprintf "%.2f", celsius_fahrenheit($_[0] - KELVIN)
        },
    },
    distance => {
        meter_inch => sub { sprintf "%.3f", meter_inch($_[0]) },
        inch_meter => sub { sprintf "%.3f", inch_meter($_[0]) },
        meter_foot => sub { sprintf "%.3f", meter_foot($_[0]) },
        foot_meter => sub { sprintf "%.3f", foot_meter($_[0]) },
        inch_foot => sub { sprintf "%.3f", inch_foot($_[0]) },
        foot_inch => sub { sprintf "%.3f", foot_inch($_[0]) },
    },
);

sub convert {
    my ($self, $run) = @_;
    my $param = $run->parameters;
    my $type = $param->{type};
    my $source = $param->{source};
    my $targets = $param->{target};
    my $value = $param->{value};
    for my $target (@$targets) {
        my $key = $source . '_' . $target;
        my $sub = $conversions{ $type }->{ $key };
        my $result = $sub->($value);
        my $label = $units{ $type }->{ $target }->{label};
        $run->out("$result$label");
    }
}

sub config {
    my ($self, $run, $args) = @_;
    my $opt = $run->options;
    my $param = $run->parameters;
    if ($ENV{PERL5_APPSPECRUN_TEST}) {
        $run->out("Options: " . $self->_dump_hash($opt));
        return;
    }
    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$opt], ['opt']);
}

sub convert_complete {
    my ($self, $run, $args) = @_;
    my $errors = $run->validation_errors;
    my $runmode = $args->{runmode};
    return if ($runmode ne "completion" and $runmode ne "validation");
    my $comp_param = $args->{parameter};
    my $param = $run->parameters;

    if ($comp_param eq 'type') {
        return [sort keys %units];
    }
    if (delete $errors->{parameters}->{type}) {
        $run->err("Invalid type\n");
        return;
    }
    if ($comp_param eq 'source') {
        my $type = $param->{type};
        my $units = $units{ $type };
        return [map {
            +{ name => $_, description => $units->{ $_ }->{label} }
        } keys %$units];
    }
    if (delete $errors->{parameters}->{source}) {
        $run->err("Invalid source\n");
        return;
    }
    delete $errors->{parameters}->{target};
    if (delete $errors->{parameters}->{value}) {
        $run->err("Invalid value\n");
        return;
    }
    if ($comp_param eq 'target') {
        my $type = $param->{type};
        my $source = $param->{source};
        my $value = $param->{value};
        my $units = $units{ $type };
        my @result;
        if ($runmode eq "validation") {
            return [sort keys %$units];
        }
        for my $unit (sort keys %$units) {
            next if $unit eq $source;
            my $label = $units->{ $unit }->{label};
            my $key = $source . '_' . $unit;
            my $sub = $conversions{ $type }->{ $key };
            my $result = $sub->($value);
            if ($ENV{PERL5_APPSPECRUN_TEST}) {
                push @result, $unit;
            }
            else {
                push @result, {
                    name => $unit,
                    description => "$result$label",
                };
            }
        }
        return \@result;
    }
}

1;
