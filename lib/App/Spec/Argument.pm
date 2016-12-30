# ABSTRACT: App::Spec objects representing command line options or parameters
use strict;
use warnings;
package App::Spec::Argument;

our $VERSION = '0.000'; # VERSION

use Moo;
use App::Spec::Types qw(ArgumentCompletion ArgumentValues);
use Types::Standard qw(Str Bool ArrayRef);

has name => (
    is => 'ro',
    required => 1,
    isa => Str,
);

has type => ( is => 'ro' );

has [qw(multiple mapping required unique)] => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

has [qw(summary description)] => (
    is => 'ro',
    isa => Str,
);

has completion => (
    is => 'ro',
    isa => ArgumentCompletion,
    default => 0,
);

has enum => (
    is => 'ro',
    isa => ArrayRef[Str],
);

has default => (
    is => 'ro',
    isa => Str,
);

has values => (
    is => 'ro',
    isa => ArgumentValues,
);

sub common {
    my ($class, %args) = @_;
    my %dsl;
    if (defined $args{spec}) {
        %dsl = $class->from_dsl(delete $args{spec});
    }
    my $description = $args{description};
    my $summary = $args{summary};
    $summary //= '';
    $description //= '';
    my $type = $args{type} // 'string';
    my %hash = (
        name => $args{name},
        summary => $summary,
        description => $description,
        type => $type,
        multiple => $args{multiple} ? 1 : 0,
        mapping => $args{mapping} ? 1 : 0,
        required => $args{required} ? 1 : 0,
        unique => $args{unique} ? 1 : 0,
        default => $args{default},
        completion => $args{completion},
        enum => $args{enum},
        values => $args{values},
        %dsl,
    );
    not defined $hash{ $_ } and delete $hash{ $_ } for keys %hash;
    return %hash;
}

my $name_re = qr{[\w-]+};

sub from_dsl {
    my ($class, $dsl) = @_;
    my %hash;

    my $name;
    my $type = "flag";
    my $multiple = 0;
    my $mapping = 0;
    my $required = 0;
    $dsl =~ s/^\s+//;

    if ($dsl =~ s/^\+//) {
        $required = 1;
    }

    if ($dsl =~ s/^ ($name_re) //x) {
        $name = $1;
        $hash{name} = $name;
    }
    else {
        die "invalid spec: '$dsl'";
    }

    my @aliases;
    while ($dsl =~ s/^ \| (\w) //x) {
        push @aliases, $1;
    }
    if (@aliases) {
        $hash{aliases} = \@aliases;
    }

    my $getopt_type = '';
    if ($dsl =~ s/^=//) {
        # not a flag, default string
        $type = "string";
        # TODO support all of Getopt::Long types
        if ($dsl =~ s/^([is])//) {
            $getopt_type = $1;
            if ($getopt_type eq "i") {
                $type = "integer";
            }
            elsif ($getopt_type eq "s") {
            }
            else {
                die "Option $name: type $getopt_type not supported";
            }
        }
    }

    if ($type eq 'flag' and $dsl =~ s/^\+//) {
        # incremental flag
        $multiple = 1;
    }
    elsif ($type eq 'string' and $dsl =~ s/^\@//) {
        $multiple = 1;
    }
    elsif ($type eq 'string' and $dsl =~ s/^\%//) {
        $multiple = 1;
        $mapping = 1;
    }

    $dsl =~ s/^\s+//;

    while ($dsl =~ s/^\s*([=+])(\S+)//) {
        if ($1 eq '+') {
            $type = $2;
            if ($getopt_type and $type ne $getopt_type) {
                die "Explicit type '$type' conflicts with getopt type '$getopt_type'";
            }
        }
        else {
            $hash{default} = $2;
        }
    }

    if ($dsl =~ s/^\s*--\s*(.*)//) {
        # TODO only summary should be supported
        $hash{summary} = $1;
    }

    if (length $dsl) {
        die "Invalid spec: trailing '$dsl'";
    }

    $hash{type} = $type;
    $hash{multiple} = $multiple;
    $hash{mapping} = $mapping;
    $hash{required} = $required;
    return %hash;
}

1;

=pod

=head1 NAME

App::Spec::Argument - App::Spec objects representing command line options or parameters

=head1 SYNOPSIS

=head1 EXAMPLES

Options can be defined in a verbose way via key value pairs, but you can also
use a shorter syntax.

The idea comes from Ingy's L<http://www.schematype.org/>.

The first item of the string is the name of the option using a syntax
very similar to the one from L<Getopt::Long>.

Then you can optionally define a type, a default value and a summary.

You can see a list of supported syntax in this example from C<t/data/12.dsl.yaml>:

=for comment
START INLINE t/data/12.dsl.yaml

    ---
    # version with short dsl syntax
    name: myapp
    appspec: { version: 0.001 }
    class: App::Spec::Example::MyApp
    title: My Very Cool App
    options:
      - spec: foo                 --Foo
      - spec: verbose|v+          --be verbose
      - spec: +req                --Some required flag
      - spec: number=i            --integer option
      - spec: number2|n= +integer --integer option
      - spec: date|d=s =today
      - spec: items=s@            --multi option
      - spec: set=s%              --multiple key=value pairs
    
    ---
    # version with verbose syntax
    name: myapp
    appspec: { version: 0.001 }
    class: App::Spec::Example::MyApp
    title: My Very Cool App
    options:
      - name: foo
        type: flag
        summary: Foo
      - name: verbose
        summary: be verbose
        type: flag
        multiple: true
        aliases: ["v"]
      - name: req
        summary: Some required flag
        required: true
        type: flag
      - name: number
        summary: integer option
        type: integer
      - name: number2
        summary: integer option
        type: integer
        aliases: ["n"]
      - name: date
        type: string
        default: today
        aliases: ["d"]
      - name: items
        type: string
        multiple: true
        summary: multi option
      - name: set
        type: string
        multiple: true
        mapping: true
        summary: multiple key=value pairs
    


=for comment
STOP INLINE

=head1 METHODS

=over 4

=item common

Builds a hash with the given hashref and fills in some defaults.

    my %hash = $class->common($args);

=item from_dsl

Builds a hash from the dsl string

    %dsl = $class->from_dsl("verbose|v+ --Be verbose");


=item name, type, multiple, required, unique, summary, description, default, completion, enum, values, mapping

Attributes which represent the ones from the spec.

=back

=cut
