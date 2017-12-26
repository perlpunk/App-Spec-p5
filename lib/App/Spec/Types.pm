# ABSTRACT: type constraints and coercions
use strict;
use warnings;
package App::Spec::Types;
use Type::Library -base,
    -declare => qw(
                      AppSpec
                      SpecOption SpecParameter SpecSubcommand
              );
use Type::Utils -all;
use Types::Standard -types;
use namespace::clean;

class_type AppSpec, { class => 'App::Spec' };

class_type SpecOption, { class => 'App::Spec::Option' };
class_type SpecParameter, { class => 'App::Spec::Parameter' };
class_type SpecSubcommand, { class => 'App::Spec::Subcommand' };

1;
