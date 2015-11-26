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

## TODO
* Write a schema
* Complete the help output
* Generate pod, man pages
* Allow Getopt::Long, Getopt::Long::Descriptive, ... input as a specification
* Allow caching of dynamic completion values that take long to compute
