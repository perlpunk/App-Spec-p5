# ABSTRACT: type constraints and coercions
use strict;
use warnings;
package App::Spec::Types;
use Type::Library -base,
    -declare => qw( AppSpec RunOutputType ArgumentCompletion CompletionItem ArgumentValues);
use Type::Utils -all;
use Types::Standard -types;
use namespace::clean;

class_type AppSpec, { class => 'App::Spec' };
enum RunOutputType, [qw( plain data )];

# Str | { replace => 'SELF' } | { replace => [ SHELL_WORDS => Int ] }
union CompletionItem, [
    Str,
    Dict[replace => ( Enum['SELF'] | Tuple[Enum['SHELL_WORDS'],Int] )],
];

union ArgumentCompletion, [
    Bool,
    Dict[op => Str|CodeRef],
    Dict[command => ArrayRef[CompletionItem]],
    Dict[command_string => Str],
];

union ArgumentValues, [
    Dict[op => Str|CodeRef],
    Dict[mapping => HashRef[ArrayRef[Str]|Str|Undef]],
];

1;
