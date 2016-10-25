use strict;
use warnings;
package App::Spec::Run::Output;

use Moose;

has type => ( is => 'rw', default => 'plain' );
has error => ( is => 'rw' );
has content => ( is => 'rw' );

1;
