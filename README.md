# App::Spec
Writing command line apps made easy

## Status

This is still a draft. Structure of the spec will change.

I wait for your suggestions, wishes, bug reports.

## Purpose

Write a specification for your command line application (currently in YAML) and get:
* Subcommands (nested), options, parameters
* a Perl 5 (and possibly other) framework that
 * automatically calls the specified method for the subcommand
 * validates options and parameters
 * outputs help
* Automatic creation of pod, man pages
* Automatic creation of zsh and bash completion scripts. Completion includes:
 * Subcommands, parameter values, option names and option values.
 * Description for completion items are shown, in zsh builtin, in bash with a cute little trick.
 * Generating dynamic completion. When completing a parameter or option, you can call an external
 command returning possible completion values
* Possibly even creating a specification for your favourite app which lacks shell completion

Writing the specification in YAML takes advantage of YAML aliases, for example when you have
options or parameters which are not global, but are used in more than one place. Alternatively the
spec could allow to create definitions which you can just link to, kind of like Swagger does it.

## Documentation

For now just an example in the examples directory called "myapp".
Just play with it and use your tab key!
Also try zsh if you haven't yet.

There is also a command line tool called app-spec <https://github.com/perlpunk/App-AppSpec-p5>
which is useful if you only have a spec file but no app.

For a first overview, here is how an app looks like:

```perl
use strict;
use warnings;
use 5.010;
# your app class
# you could even go without an extra class and simply use the "main" namespace
package App::Spec::Example::MyApp;
use base 'App::Spec::Run';

# the method for the subcommand frobnicate
sub frobnicate {
    my ($self) = @_;
    my $options = $self->options; # just a hashref
    my $parameters = $self->parameters; # just a hashref
    say "frobnicate";
}

package main;
use App::Spec;

# read YAML from __DATA__ section
my $spec = App::Spec->read(\*DATA);
my $run = App::Spec::Example::MyApp->new({ spec => $spec });
# this will check input and call frobnicate
$run->run;

# specification follows:
__DATA__
---
name: myapp # filename of the app
version: 0.1 # app-spec schema version
title: My Very Cool App
# global options. option 'help' will be generated for you
options:
  - ...
  - ...
commands:
  frobnicate:
    summary: Frobnicate something
    op: frobnicate
    # subcommand specific options and parameters
    parameters:
      - ...
    options:
      - ...
      - ...
```
## Getting the completion to work

Here is how you get the completion for the example app.

First, add the bin directory to your path:

 `% PATH=$PWD/examples/bin:$PATH`

Locate the modules:

` % export PERL5LIB=$PWD/lib:$PERL5LIB`

### Bash

Simply source the bash completion script:
```
 $ source examples/bash/myapp.bash
 $ myapp <TAB>
```

### Zsh

When using a new script/completion, you have to do two things:

Add the path to the completion dir to your .zshrc before the compinit call:

 `fpath=('/path/to/App-Spec-p5/examples/zsh' $fpath)`

Then:

 `% exec zsh`
 
If you change the completion script later, you just need to source it:

 `% source examples/zsh/_myapp`
 
 Note that the completion script must also be executable!

## Reinventing the wheel?

Yes, I know MooseX::App::Cmd, MooseX::App::Command, MouseX::App::Cmd, MooX::Cmd. I've written https://github.com/perlpunk/MooseX-App-Plugin-ZshCompletion.

But all are a little bit different and lack things.

My use case which got me into this required automatic creation of the spec, and I would have been
forced to dynamically generate a whole bunch of Mo*X classes when I actually just needed one.

I also like the idea of having a language independent specification.

I'm lazy and I didn't want to write a completion for all the other app frameworks and getopt modules.
I just want to do it once. 

## TODO
* Write a schema
* Write tests
* Complete the help output
* Generate pod, man pages
* Allow Getopt::Long, Getopt::Long::Descriptive, ... input as a specification
* Allow caching of dynamic completion values that take long to compute
* Options/parameters imply other options
* Options with multiple values
* Allow apps without subcommands
