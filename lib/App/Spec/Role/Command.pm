use strict;
use warnings;
package App::Spec::Role::Command;

our $VERSION = '0.000'; # VERSION

use List::Util qw/ any /;
use App::Spec::Option;
use Ref::Util qw/ is_arrayref is_blessed_ref /;
use Types::Standard qw/ Map Str ArrayRef /;
use App::Spec::Types qw/ MarkupName PluginName PluginType SpecOption SpecParameter SpecSubcommand CommandOp /;

use Moo::Role;

has name => ( is => 'rw', required => 1, isa => Str );
has markup => ( is => 'rw', isa => MarkupName, default => 'pod' );
has class => ( is => 'rw', isa => Str );
has op => ( is => 'ro', isa => CommandOp );
has plugins => ( is => 'ro', isa => ArrayRef[PluginName], default => sub { +[] } );
has plugins_by_type => ( is => 'ro', isa => Map[PluginType,PluginName], default => sub { +{} } );
has options => ( is => 'rw', isa => ArrayRef[SpecOption], default => sub { +[] } );
has parameters => ( is => 'rw', isa => ArrayRef[SpecParameter], default => sub { +[] } );
has subcommands => ( is => 'rw', isa => Map[Str,SpecSubcommand], default => sub { +{} } );
has description => ( is => 'rw', isa => Str );

sub default_plugins {
    qw/ Meta Help /
}

sub has_subcommands {
    my ($self) = @_;
    return +( $self->subcommands && %{ $self->subcommands } ) ? 1 : 0;
}

around BUILDARGS => sub {
    my ($orig,$class,@etc) = @_;
    my $spec = $class->$orig(@etc);

    $spec->{options} ||= [];
    $spec->{parameters} ||= [];

    for (@{ $spec->{options} }, @{ $spec->{parameters} }) {
        $_ = { spec => $_ } unless ref $_;
    }
    $_ = App::Spec::Option->new($_) for grep { !is_blessed_ref($_) } @{ $spec->{options} || [] };
    $_ = App::Spec::Parameter->new($_) for grep { !is_blessed_ref($_) } @{ $spec->{parameters} || [] };

    my $commands = {};
    for my $name (keys %{ $spec->{subcommands} || {} }) {
        my $cmd = $spec->{subcommands}->{ $name };
        $commands->{ $name } = App::Spec::Subcommand->new(
            name => $name,
            %$cmd,
        );
    }
    $spec->{subcommands} = $commands;

    if ( defined (my $op = $spec->{op}) ) {
        die "Invalid op '$op'" unless ref($op) || $op =~ m/^\w+\z/;
    }
    if ( defined (my $class = $spec->{class}) ) {
        die "Invalid class '$class'" unless $class =~ m/^ \w+ (?: ::\w+)* \z/x;
    }

    my @plugins = $class->default_plugins;
    push @plugins, @{ $spec->{plugins} || [] };
    for my $plugin (@plugins) {
        unless ($plugin =~ s/^=//) {
            $plugin = "App::Spec::Plugin::$plugin";
        }
    }
    $spec->{plugins} = \@plugins;

    return $spec;
};

# back-compat for old versions
sub build {
    my ($class, @spec) = @_;
    my $self = $class->new(@spec);
}

sub read {
    my ($class, $file) = @_;
    unless (defined $file) {
        die "No filename given";
    }

    my $spec = $class->load_data($file);

    my $self = $class->new($spec);

    $self->load_plugins;
    $self->init_plugins;

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

sub load_plugins {
    my ($self) = @_;
    my $plugins = $self->plugins;
    if (@$plugins) {
        require Module::Runtime;
        for my $plugin (@$plugins) {
            my $loaded = Module::Runtime::require_module($plugin);
        }
    }
}

sub init_plugins {
    my ($self) = @_;
    my $plugins = $self->plugins;
    if (@$plugins) {
        my $options = $self->options;
        for my $plugin (@$plugins) {
            if ($plugin->does('App::Spec::Role::Plugin::Subcommand')) {
                push @{ $self->plugins_by_type->{Subcommand} }, $plugin;
                my $subc = $plugin->install_subcommands( spec => $self );
                $subc = [ $subc ] unless is_arrayref($subc);

                if ($self->has_subcommands) {
                    for my $cmd (@$subc) {
                        $self->subcommands->{ $cmd->name } ||= $cmd;
                    }
                }
            }

            if ($plugin->does('App::Spec::Role::Plugin::GlobalOptions')) {
                push @{ $self->plugins_by_type->{GlobalOptions} }, $plugin;
                my $new_opts = $plugin->install_options( spec => $self );
                if ($new_opts) {
                    $options ||= [];

                    for my $opt (@$new_opts) {
                        $opt = App::Spec::Option->new($opt)
                            unless is_blessed_ref($opt);
                        unless (any { $_->name eq $opt->name } @$options) {
                            push @$options, $opt;
                        }
                    }

                }
            }

        }
    }
}


1;

__END__

=pod

=head1 NAME

App::Spec::Role::Command - commands and subcommands both use this role

=head1 METHODS

=over 4

=item read

Calls load_data, new, load_plugins, init_plugins

=item new

This builds a tree of objects

    my $self = App::Spec->new(%$hashref);
    my $self = App::Spec::Subcommand->new(%$hashref);

=item load_data

    my $spec = App::Spec->load_data($file);

Takes a filename as a string, a filehandle, a ref to a YAML string or
a hashref.

=item default_plugins

Returns ('Meta', 'Help')

=item has_subcommands

Returns 1 if there are any subcommands defined.

=item init_plugins

Initialize plugins

=item load_plugins

Loads the specified plugin modules.

=item plugins_by_type

    my $p = $cmd->plugins_by_type->{Subcommand};

=back

=head1 ATTRIBUTES

=over 4

=item class

Specifies the class which implements the app.

=item op, description, markup, name, options, parameters, plugins, subcommands

Accessors for specification items

=back


=cut
