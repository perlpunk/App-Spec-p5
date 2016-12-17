use strict;
use warnings;
package App::Spec::Role::Command;

use List::Util qw/ any /;

use Moo::Role;

has name => ( is => 'rw' );
has appspec => ( is => 'rw' );
has markup => ( is => 'rw', default => 'pod' );
has class => ( is => 'rw' );
has op => ( is => 'ro' );
has options => ( is => 'rw', default => sub { +[] } );
has parameters => ( is => 'rw', default => sub { +[] } );
has subcommands => ( is => 'rw', default => sub { +{} } );
has description => ( is => 'rw' );

sub has_subcommands {
    my ($self) = @_;
    return $self->subcommands ? 1 : 0;
}

sub build {
    my ($class, %spec) = @_;
    $spec{options} ||= [];
    $spec{parameters} ||= [];
    for (@{ $spec{options} }, @{ $spec{parameters} }) {
        $_ = { spec => $_ } unless ref $_;
    }
    $_ = App::Spec::Option->build(%$_) for @{ $spec{options} || [] };
    $_ = App::Spec::Parameter->build(%$_) for @{ $spec{parameters} || [] };

    my $commands;
    for my $name (keys %{ $spec{subcommands} || {} }) {
        my $cmd = $spec{subcommands}->{ $name };
        $commands->{ $name } = App::Spec::Subcommand->build(
            name => $name,
            %$cmd,
        );
    }
    $spec{subcommands} = $commands;

    if ( defined (my $op = $spec{op}) ) {
        die "Invalid op '$op'" unless $op =~ m/^\w+\z/;
    }
    if ( defined (my $class = $spec{class}) ) {
        die "Invalid class '$class'" unless $class =~ m/^ \w+ (?: ::\w+)* \z/x;
    }

    my $self = $class->new(%spec);
}

sub read {
    my ($class, $file) = @_;
    unless (defined $file) {
        die "No filename given";
    }

    my $spec = $class->load_data($file);

    my $has_subcommands = $spec->{subcommands} ? 1 : 0;

    my $default;
    {
        $default = $class->_read_default_spec;

        for my $opt (@{ $default->{options} }) {
            my $name = $opt->{name};
            # TODO
            # this should be moved somewhere else since the name might not
            # be parsed from dsl yet
            no warnings 'uninitialized';
            unless (any { (ref $_ ? $_->{name} : $_) eq $name } @{ $spec->{options} }) {
                push @{ $spec->{options} }, $opt;
            }
        }

        if ($has_subcommands) {
            for my $key (keys %{ $default->{subcommands} } ) {
                my $cmd = $default->{subcommands}->{ $key };
                $spec->{subcommands}->{ $key } ||= $cmd;
            }
        }
    }

    my $commands;
    if ($has_subcommands) {
        # add subcommands to help command
        my $help_subcmds = $spec->{subcommands}->{help}->{subcommands} ||= {};
        $class->_add_subcommands($help_subcmds, $spec->{subcommands}, { subcommand_required => 0 });

        for my $name (keys %{ $spec->{subcommands} || [] }) {
            my $cmd = $spec->{subcommands}->{ $name };
            $commands->{ $name } = App::Spec::Subcommand->build(
                name => $name,
                %$cmd,
            );
        }
    }

    $spec->{subcommands} = $commands;


    my $self = $class->build(%$spec);

    return $self;
}

sub load_data {
    my ($class, $file) = @_;
    my $spec;
    if (ref $file eq 'GLOB') {
        my $data = do { local $/; <$file> };
        $spec = eval { YAML::XS::Load($data) };
    }
    elsif (not ref $file) {
        $spec = eval { YAML::XS::LoadFile($file) };
    }
    elsif (ref $file eq 'SCALAR') {
        my $data = $$file;
        $spec = eval { YAML::XS::Load($data) };
    }
    elsif (ref $file eq 'HASH') {
        $spec = $file;
    }

    unless ($spec) {
        die "Error reading '$file': $@";
    }
    return $spec;
}

sub _add_subcommands {
    my ($self, $commands1, $commands2, $ref) = @_;
    for my $name (keys %{ $commands2 || {} }) {
        next if $name eq "help";
        my $cmd = $commands2->{ $name };
        $commands1->{ $name } = {
            name => $name,
            subcommands => {},
            %$ref,
        };
        my $subcmds = $cmd->{subcommands} || {};
        $self->_add_subcommands($commands1->{ $name }->{subcommands}, $subcmds, $ref);
    }
}


1;
