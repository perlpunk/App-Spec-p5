package App::Spec::Example::MySimpleApp;
use warnings;
use strict;
use 5.010;

use base 'App::Spec::Run';

use App::Spec::Example::MyApp;

sub execute {
    my ($self) = @_;
    my $opt = $self->options;
    my $param = $self->parameters;
    if ($ENV{PERL5_APPSPECRUN_TEST}) {
        say "Options: " . App::Spec::Example::MyApp->_dump_hash($opt);
        say "Parameters: " .  App::Spec::Example::MyApp->_dump_hash($param);
        return;
    }

}

1;
