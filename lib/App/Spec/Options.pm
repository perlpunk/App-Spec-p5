use strict;
use warnings;
package App::Spec::Options;

our $VERSION = '0.000'; # VERSION;

use List::Util qw/ any /;
use Moo;

has options => ( is => 'ro' );
has option_specs => ( is => 'ro' );
has parameters => ( is => 'ro' );
has param_specs => ( is => 'ro' );
has config => ( is => 'ro' );

my %validate = (
    string => sub { length($_[0]) > 0 },
    file => sub { -f $_[0] },
    dir => sub { -d $_[0] },
    integer => sub { $_[0] =~ m/^[+-]?\d+/ },
    bool => sub { 1 },
    enum => sub {
        my ($value, $list) = @_;
        any { $value eq $_ } @$list;
    },
);

sub process {
    my ($self, $errs, %args) = @_;
    my $app = $args{app};
    my $type = $args{type};
    my $config = $self->config;
    my ($items, $specs);
    if ($args{type} eq "parameters") {
        $items = $self->parameters;
        $specs = $self->param_specs;
    }
    else {
        $items = $self->options;
        $specs = $self->option_specs;
    }
    for my $name (sort keys %$specs) {
        my $spec = $specs->{ $name };
        my $value = $items->{ $name };

        if (not defined $value) {
            if ($spec->required
                and (($config->{required} // '') ne 'ignore')) {
                $errs->{ $type }->{ $name } = "missing";
                next;
            }
            if (defined (my $default = $spec->default)
                and (($config->{defult} // '') ne 'ignore')) {
                $value = $default;
                $items->{ $name } = $value;
            }
            else {
                next;
            }
        }

        if (my $filter = $spec->filter) {
            my $method = $filter->{method}
                or warn "Missing method for filter for $type '$name'";
            $value = $app->$method(
                $name => $value, $self->parameters, $self->options,
            );
        }

        my $param_type = $spec->{type};
        my $def;
        if (ref $param_type eq 'HASH') {
            ($param_type, $def) = %$param_type;
        }
        my $code = $validate{ $param_type }
            or die "Missing method for validation type $param_type";
        my $ok = $code->($value, $def);
        unless ($ok) {
            $errs->{ $type }->{ $name } = "invalid $param_type";
        }
    }
    return (keys %$errs) ? 0 : 1;
}

1;
