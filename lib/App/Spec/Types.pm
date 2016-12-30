# ABSTRACT: type constraints and coercions
use strict;
use warnings;
package App::Spec::Types;
use Type::Library -base,
    -declare => qw( AppSpec RunOutputType ArgumentCompletion ArgumentValues);
use Type::Utils -all;
use Types::Standard -types;
use namespace::clean;

class_type AppSpec, { class => 'App::Spec' };
enum RunOutputType, [qw( plain data )];

union ArgumentCompletion, [
    Bool,
    Dict[op => Str|Code],
    Dict[command => ArrayRef[Str]],
    Dict[command_string => Str],
];

union ArgumentValues, [
    Dict[op => Str|Code],
    Dict[mapping => HashRef[Str]],
];

1;
