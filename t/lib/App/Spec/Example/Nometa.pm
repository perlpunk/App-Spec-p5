package App::Spec::Example::Nometa;
use strict;
use warnings;
use 5.010;

use base 'App::Spec::Run::Cmd';

sub foo {
    my ($self, $run) = @_;
    $run->out("foo");

}

1;
