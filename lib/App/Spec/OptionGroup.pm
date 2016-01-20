use strict;
use warnings;
package App::Spec::OptionGroup;

our $VERSION = '0.000'; # VERSION

use Moo;

has name => ( is => 'ro' );
has summary => ( is => 'ro' );
has description => ( is => 'ro' );
has options => ( is => 'ro' );
has allowed_number => ( is => 'ro' );

sub build {
    my ($class, $args) = @_;
    my $description = $args->{description};
    my $summary = $args->{summary};
    $summary //= $description // '';
    $description //= $summary;

    my $self = $class->new({
        name => $args->{group},
        summary => $summary,
        description => $description,
        options => $args->{options} // [],
        allowed_number => $args->{allowed_number} // [],
    });
    return $self;
}

1;
