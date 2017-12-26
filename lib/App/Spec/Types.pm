# ABSTRACT: type constraints and coercions
use strict;
use warnings;
package App::Spec::Types;
use Type::Library -base,
    -declare => qw(
                      AppSpec
              );
use Type::Utils -all;
use Types::Standard -types;
use namespace::clean;

class_type AppSpec, { class => 'App::Spec' };

1;
