use strict;
use warnings;
package App::Spec::Run::Validator;

our $VERSION = '0.000'; # VERSION;

use List::Util qw/ any /;
use List::MoreUtils qw/ uniq /;
use Ref::Util qw/ is_arrayref is_hashref /;
use Moo;

has options => ( is => 'ro' );
has option_specs => ( is => 'ro' );
has parameters => ( is => 'ro' );
has param_specs => ( is => 'ro' );

my %validate = (
    string => sub { length($_[0]) > 0 },
    file => sub { $_[0] eq '-' or -f $_[0] },
    dir => sub { -d $_[0] },
    integer => sub { $_[0] =~ m/^[+-]?\d+$/ },
    flag => sub { 1 },
    enum => sub {
        my ($value, $list) = @_;
        any { $value eq $_ } @$list;
    },
);

sub process {
    my ($self, $errs, %args) = @_;
    my $app = $args{app};
    my $type = $args{type};
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
        my $param_type = $spec->type;
        my $enum = $spec->enum;

        if ($spec->type eq "flag") {
            if ($spec->multiple) {
                if (defined $value and $value !~ m/^\d+$/) {
                    die "Value for '$name': '$value' shouldn't happen";
                }
            }
            else {
                if (defined $value and $value != 1) {
                    die "Value for '$name': '$value' shouldn't happen";
                }
            }
            next;
        }

        my $values;
        if ($spec->multiple) {
            if (not defined $value) {
                $items->{ $name } = $value = [];
            }
            $values = $value;

            if (not @$values) {
                if (defined (my $default = $spec->default)) {
                    $values = [ $default ];
                    $items->{ $name } = $values;
                }
            }

            if ( not @$value and $spec->required) {
                $errs->{ $type }->{ $name } = "missing";
                next;
            }

            if (not @$value) {
                next;
            }

            if ($spec->unique and (uniq @$values) != @$values) {
                $errs->{ $type }->{ $name } = "not_unique";
                next;
            }

        }
        else {

            if (not defined $value) {
                if (defined (my $default = $spec->default)) {
                    $value = $default;
                    $items->{ $name } = $value;
                }
            }

            if ( not defined $value and $spec->required) {
                $errs->{ $type }->{ $name } = "missing";
                next;
            }

            if (not defined $value) {
                next;
            }

            $values = [ $value ];
        }

        if (my $filter = $spec->filter) {
            my $method = $filter->{method}
                or warn "Missing method for filter for $type '$name'";
            @$values = map {
                $app->$method(
                    $name => $_, $self->parameters, $self->options,
                );
            } @$values;
        }

        my $def;
        if (ref $param_type eq 'HASH') {
            ($param_type, $def) = %$param_type;
        }
        my $code = $validate{ $param_type }
            or die "Missing method for validation type $param_type";

        my $possible_values = [];
        if (my $spec_values = $spec->values) {
            my $op = $spec_values->{op};
            my $args = {
                runmode => "validation",
                parameter => $name,
            };
            $possible_values = $app->cmd->$op($self, $args) || [];
        }

        for my $v (@$values) {
            # check type validity
            my $ok = $code->($v, $def);
            unless ($ok) {
                $errs->{ $type }->{ $name } = "invalid $param_type";
            }
            # check static enums
            if ($enum) {
                my $code = $validate{enum}
                    or die "Missing method for validation type enum";
                my $ok = $code->($v, $enum);
                unless ($ok) {
                    $errs->{ $type }->{ $name } = "invalid enum";
                }
            }
            if ($param_type eq 'file' and $v eq '-') {
                $v = do { local $/; my $t = <STDIN>; \$t };
                $items->{ $name } = $v;
            }
            if (@$possible_values) {
                my $ok = any {
                    is_hashref($_) ? $_->{name} eq $v : $_ eq $v
                } @$possible_values;
                unless ($ok) {
                    $errs->{ $type }->{ $name } = "invalid value";
                }
            }
        }
    }
    return (keys %$errs) ? 0 : 1;
}

1;
