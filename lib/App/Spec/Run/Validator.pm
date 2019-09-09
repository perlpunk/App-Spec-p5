# ABSTRACT: Processes and validates options and parameters
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
    filename => sub { 1 },
    dir => sub { -d $_[0] },
    dirname => sub { 1 },
    integer => sub { $_[0] =~ m/^[+-]?\d+$/ },
    float => sub { $_[0] =~ m/^[+-]?\d+(?:\.\d+)?$/ },
    flag => sub { 1 },
    enum => sub {
        my ($value, $list) = @_;
        any { $value eq $_ } @$list;
    },
);

sub process {
    my ($self, $run, $errs) = @_;
    my ($ok) = $self->_process( $errs, type => "parameters", app => $run );
    $ok &&= $self->_process( $errs, type => "options", app => $run );
    return $ok;
}

sub _process {
    my ($self, $errs, %args) = @_;
    my $run = $args{app};
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

    # TODO: iterate over parameters in original cmdline order
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
        if ($spec->multiple and $spec->mapping) {
            if (not defined $value) {
                $items->{ $name } = $value = {};
            }
            $values = $value;

            if (not keys %$values) {
                if (defined (my $default = $spec->default)) {
                    $values = { split m/=/, $default, 2 };
                    $items->{ $name } = $values;
                }
            }

            if (not keys %$values and $spec->required) {
                $errs->{ $type }->{ $name } = "missing";
                next;
            }

            if (not keys %$values) {
                next;
            }

        }
        elsif ($spec->multiple) {
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

            if ( not @$values and $spec->required) {
                $errs->{ $type }->{ $name } = "missing";
                next;
            }

            if (not @$values) {
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

        my $def;
        if (ref $param_type eq 'HASH') {
            ($param_type, $def) = %$param_type;
        }
        my $code = $validate{ $param_type }
            or die "Missing method for validation type $param_type";

        my $possible_values = $spec->mapping ? {} : [];
        if (my $spec_values = $spec->values) {
            if (my $op = $spec_values->{op}) {
                my $args = {
                    runmode => "validation",
                    parameter => $name,
                };
                $possible_values = $run->cmd->$op($run, $args) || [];
            }
            elsif ($spec->mapping) {
                $possible_values = $spec_values->{mapping};
            }
            else {
                $possible_values = $values->{enum};
            }
        }

        my @to_check = $spec->mapping
            ? map { [ $_ => $values->{ $_ } ] } keys %$values
            : @$values;
        for my $item (@to_check) {
            my ($key, $v);
            if ($spec->mapping) {
                ($key, $v) = @$item;
            }
            else {
                $v = $item;
            }
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
                # TODO does not work for multiple
                $items->{ $name } = $v;
            }

            if ($spec->mapping and keys %$possible_values) {
                my $ok = 0;
                if (exists $possible_values->{ $key }) {
                    if (my $list = $possible_values->{ $key }) {
                        $ok = any { $_ eq $v } @$list;
                    }
                    else {
                        # can have any value
                        $ok = 1;
                    }
                }
                unless ($ok) {
                    $errs->{ $type }->{ $name } = "invalid value";
                }
            }
            elsif (@$possible_values) {
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

__END__

=pod

=head1 NAME

App::Spec::Run::Validator - Processes and validates options and parameters

=head1 METHODS

=over 4

=item process

    my %errs;
    my $ok = $validator->process( $run, \%errs );

Returns 1 or 0. In case of validation errors, it fills C<%errs>.

=back

=head1 ATTRIBUTES

=over 4

=item options

Holds the read commandline options

=item parameters

Holds the read commandline parameters

=item option_specs

Holds the items from App::Spec for options

=item param_specs

Holds the items from App::Spec for parameters

=back

=cut
