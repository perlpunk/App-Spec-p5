use strict;
use warnings;
package App::Spec::Subcommand;

our $VERSION = '0.000'; # VERSION

use App::Spec::Option;
use App::Spec::Parameter;

use Moo;

with('App::Spec::Role::Command');

has summary => ( is => 'ro' );
has subcommand_required => ( is => 'ro' );

sub default_plugins { }

1;
