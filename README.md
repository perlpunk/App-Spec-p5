# App::Spec
Writing command line apps made easy

## Status

This is still a draft.

## Purpose

Write a specification for your command line application (currently in YAML) and get:
* Subcommands (nested), options, parameters
* a Perl 5 (and possibly other) framework that automatically calls the specified method for
the subcommand, validates options and parameters, and outputs help
* automatic creation of zsh and bash completion script. Completion includes:
 * subcommands, parameter values, option names and option values.
 * Description for completion items are shown, in zsh builtin, in bash with a cute little trick.
 * generating dynamic completion. When completing a parameter or option, you can call an external
 command returning possible completion values
* possibly even creating a specification for your favourite app which lacks shell completion

## Documentation

For now just an example app in the examples directory called "myapp".
Just play with it and use your tab key!
Also try zsh if you haven't yet.

## Reinventing the wheel?

Yes, I know MooseX::App::Cmd, MooseX::App::Command, MouseX::App::Cmd, MooX::Cmd. I've written https://github.com/perlpunk/MooseX-App-Plugin-ZshCompletion.

But all are lacking things. Also my use case which got me to
this required automatic creation of the spec, and I would have been forced to dynamically generate
a whole bunch of Mo*X classes when I actually just needed one.
Having a language independent spec can also be useful.

I'm lazy and I didn't want to write a completion for all the other app frameworks and getopt modules.
I just want to do it once. 

## TODO
* Write a schema
* Complete the help output
* Generate pod, man pages
* Allow Getopt::Long, Getopt::Long::Descriptive, ... input as a specification
* Allow caching of dynamic completion values that take long to compute
