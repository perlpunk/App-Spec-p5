use strict;
use warnings;
package App::Spec::Pod;

use Text::Table;

use Moo;

has spec => ( is => 'ro' );

sub generate {
    my ($self) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $title = $spec->title;
    my $abstract = $spec->abstract;
    my $description = $spec->description;
    my $subcmds = $spec->subcommands;
    my $global_options = $spec->options;

    my @subcmd_pod = $self->subcommand_pod(
        commands => $subcmds,
    );
    my $option_string = '';
    if (@$global_options) {
        $option_string = "=head2 GLOBAL OPTIONS\n\n" . $self->options2pod(
            options => $global_options,
        );
    }

    my $pod = <<"EOM";
\=head1 NAME

$appname - $title

\=head1 ABSTRACT

$abstract

\=head1 DESCRIPTION

$description

$option_string

\=head2 SUBCOMMANDS

@{[ join '', @subcmd_pod ]}
EOM

}

sub subcommand_pod {
    my ($self, %args) = @_;
    my $spec = $self->spec;
    my $appname = $spec->name;
    my $commands = $args{commands};
    my $previous = $args{previous} || [];

    my @pod;
    my %keys;
    @keys{ keys %$commands } = ();
    my @keys;
    if (@$previous) {
        @keys = sort keys %keys;
    }
    else {
        for my $key (qw/ help _complete /) {
            if (exists $keys{ $key }) {
                push @keys, $key;
                delete $keys{ $key };
            }
        }
        unshift @keys, sort keys %keys;
    }
    for my $name (@keys) {
        my $cmd_spec = $commands->{ $name };
        my $name = $cmd_spec->name;
        my $summary = $cmd_spec->summary;
        my $description = $cmd_spec->description;
        my $subcmds = $cmd_spec->subcommands;
        my $parameters = $cmd_spec->parameters;
        my $options = $cmd_spec->options;

        my $desc = '';
        if (length $summary) {
            $desc .= "$summary\n\n";
        }
        if (length $description) {
            $desc .= "$description\n\n";
        }

        my $usage = "$appname @$previous $name";
        if (keys %$subcmds) {
            $usage .= " <subcommands>";
        }

        my $option_string = '';
        if (@$options) {
            $usage .= " [options]";
            $option_string = "Options:\n\n" . $self->options2pod(
                options => $options,
            );
        }

        if (length $option_string) {
            $desc .= "$option_string\n";
        }

        my $param_string = '';
        if (@$parameters) {
            $param_string = "Parameters:\n\n" . $self->params2pod(
                parameters => $parameters,
            );
            for my $param (@$parameters) {
                my $name = $param->name;
                my $required = $param->required;
                $usage .= $required ? " <$name>" : " [<$name>]";
            }
        }
        if (length $param_string) {
            $desc .= $param_string;
        }

        my $pod = <<"EOM";
\=head3 @$previous $name

    $usage

$desc
EOM
        if (keys %$subcmds and $name ne "help") {
            my @sub = $self->subcommand_pod(
                previous => [@$previous, $name],
                commands => $subcmds,
            );
            $pod .= join '', @sub;
        }
        push @pod, $pod;
    }
    return @pod;
}

sub params2pod {
    my ($self, %args) = @_;
    my $params = $args{parameters};
    my @rows;
    my $tb = Text::Table->new;
    for my $param (@$params) {
        my $required = $param->required ? '*' : '';
        push @rows, ["    " . $param->name, " " . $required, $param->description];
    }
    $tb->load(@rows);
    return "$tb";
}

sub options2pod {
    my ($self, %args) = @_;
    my $options = $args{options};
    my @rows;
    my $tb = Text::Table->new;
    for my $opt (@$options) {
        my $name = $opt->name;
        my $aliases = $opt->aliases;
        my $description = $opt->description;
        my $required = $opt->required ? '*' : '';
        my @names = map {
            length $_ > 1 ? "--$_" : "-$_"
        } ($name, @$aliases);
        push @rows, ["    @names", " " . $required, $description];
    }
    $tb->load(@rows);
    return "$tb";
}

1;
