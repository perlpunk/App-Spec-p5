use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'App/Spec.pm',
    'App/Spec/Argument.pm',
    'App/Spec/Completion.pm',
    'App/Spec/Completion/Bash.pm',
    'App/Spec/Completion/Zsh.pm',
    'App/Spec/Option.pm',
    'App/Spec/Parameter.pm',
    'App/Spec/Plugin/Format.pm',
    'App/Spec/Plugin/Help.pm',
    'App/Spec/Plugin/Meta.pm',
    'App/Spec/Pod.pm',
    'App/Spec/Role/Command.pm',
    'App/Spec/Role/Plugin.pm',
    'App/Spec/Role/Plugin/GlobalOptions.pm',
    'App/Spec/Role/Plugin/Subcommand.pm',
    'App/Spec/Run.pm',
    'App/Spec/Run/Cmd.pm',
    'App/Spec/Run/Output.pm',
    'App/Spec/Run/Response.pm',
    'App/Spec/Run/Validator.pm',
    'App/Spec/Schema.pm',
    'App/Spec/Subcommand.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


