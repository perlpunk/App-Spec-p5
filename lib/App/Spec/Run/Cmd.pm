# ABSTRACT: The App::Spec command which is run
use strict;
use warnings;
package App::Spec::Run::Cmd;
our $VERSION = '0.000'; # VERSION

use App::Spec::Run;
use Moo;

sub cmd_help {
    my ($self, $run) = @_;
    $run->cmd_help($self);
}

sub cmd_self_completion {
    my ($self, $run) = @_;
    $run->cmd_self_completion($self);
}

sub cmd_self_pod {
    my ($self, $run) = @_;
    $run->cmd_self_pod($self);
}

1;
