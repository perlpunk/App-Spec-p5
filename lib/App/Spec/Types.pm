# ABSTRACT: type constraints and coercions
use strict;
use warnings;
package App::Spec::Types;
use Type::Library -base,
    -declare => qw(
                      AppSpec
                      SpecOption SpecParameter SpecSubcommand
                      RunOutputType
                      ArgumentType
                      RunOutput RunResponse
                      MarkupName
                      PluginName PluginType
              );
use Type::Utils -all;
use Types::Standard -types;
use namespace::clean;

class_type AppSpec, { class => 'App::Spec' };

class_type SpecOption, { class => 'App::Spec::Option' };
class_type SpecParameter, { class => 'App::Spec::Parameter' };
class_type SpecSubcommand, { class => 'App::Spec::Subcommand' };

enum RunOutputType, [qw( plain data )];
enum ArgumentType, [qw(string file dir integer flag enum)];

class_type RunOutput, { class => 'App::Spec::Run::Output' };
class_type RunResponse, { class => 'App::Spec::Run::Response' };

enum MarkupName, [qw(pod swim)];

declare PluginName, as Str,
    where { /[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)/ };
enum PluginType, [qw(Subcommands GlobalOptions)];

1;
