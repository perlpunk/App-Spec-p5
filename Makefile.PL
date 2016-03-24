# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.043.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Specification for commandline app",
  "AUTHOR" => "Tina M\x{fc}ller <cpan2\@tinita.de>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "App-Spec",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "App::Spec",
  "PREREQ_PM" => {
    "Data::Dumper" => 0,
    "Getopt::Long" => 0,
    "List::Util" => 0,
    "Moo" => 0,
    "Storable" => 0,
    "Swim" => 0,
    "Term::ANSIColor" => 0,
    "Text::Table" => 0,
    "YAML::XS" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "FindBin" => 0,
    "IPC::Run" => 0,
    "Test::More" => 0,
    "Test::Output" => 0,
    "constant" => 0,
    "lib" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Dumper" => 0,
  "FindBin" => 0,
  "Getopt::Long" => 0,
  "IPC::Run" => 0,
  "List::Util" => 0,
  "Moo" => 0,
  "Storable" => 0,
  "Swim" => 0,
  "Term::ANSIColor" => 0,
  "Test::More" => 0,
  "Test::Output" => 0,
  "Text::Table" => 0,
  "YAML::XS" => 0,
  "base" => 0,
  "constant" => 0,
  "lib" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}