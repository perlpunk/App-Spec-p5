# ABSTRACT: type constraints and coercions
use strict;
use warnings;
package App::Spec::Types;
use Type::Library -base,
    -declare => qw(
                      AppSpec
                      SpecOption SpecParameter SpecSubcommand
                      RunOutputType
                      SpecArgumentCompletion CompletionItem SpecArgumentValues
                      ArgumentValue ArgumentType
                      RunOutput RunResponse ResponseCallbacks
                      MarkupName
                      PluginName PluginType
                      ValidationErrors
                      CommandOp
                      EventSubscriber
              );
use Type::Utils -all;
use Types::Standard -types;
use namespace::clean;

class_type AppSpec, { class => 'App::Spec' };

class_type SpecOption, { class => 'App::Spec::Option' };
class_type SpecParameter, { class => 'App::Spec::Parameter' };
class_type SpecSubcommand, { class => 'App::Spec::Subcommand' };

enum RunOutputType, [qw( plain data )];

# Str | { replace => 'SELF' } | { replace => [ SHELL_WORDS => Int ] }
union CompletionItem, [
    Str,
    Dict[replace => ( Enum['SELF'] | Tuple[Enum['SHELL_WORDS'],Int] )],
];

union CommandOp, [Str,CodeRef];

union SpecArgumentCompletion, [
    Bool,
    Dict[op => CommandOp],
    Dict[command => ArrayRef[CompletionItem]],
    Dict[command_string => Str],
];

union SpecArgumentValues, [
    Dict[op => CommandOp],
    Dict[mapping => HashRef[ArrayRef[Str]|Str|Undef]],
];

union ArgumentValue, [
    Undef,
    Str,
    ArrayRef[Str],
    HashRef[Str],
    HashRef[ArrayRef[Str]],
];

enum ArgumentType, [qw(string file dir integer flag enum)];

class_type RunOutput, { class => 'App::Spec::Run::Output' };
class_type RunResponse, { class => 'App::Spec::Run::Response' };
declare ResponseCallbacks, as Map[Str,CodeRef];

enum MarkupName, [qw(pod swim)];

declare PluginName, as Str,
    where { /[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)/ };
enum PluginType, [qw(Subcommands GlobalOptions)];

declare ValidationErrors, as Dict[
    parameters => Optional[Map[Str,Str]],
    options => Optional[Map[Str,Str]],
];

declare EventSubscriber, as Dict[
    plugin => ClassName|Object,
    method => CommandOp,
];

1;
