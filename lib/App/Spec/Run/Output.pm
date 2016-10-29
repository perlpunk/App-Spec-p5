use strict;
use warnings;
package App::Spec::Run::Output;

use Moo;

has type => ( is => 'rw', default => 'plain' );
has error => ( is => 'rw' );
has content => ( is => 'rw' );

1;
