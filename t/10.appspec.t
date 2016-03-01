use strict;
use warnings;
use Test::More tests => 3;
use Test::Output;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec::Example::MyApp;
use App::Spec;
use IPC::Run qw( run timeout );
$ENV{PERL5_APPSPECRUN_COLOR} = 'never';
my $spec = App::Spec->read("$Bin/../examples/myapp-spec.yaml");
my $app = "$Bin/../examples/bin/myapp";

my @valid = (
    {
        input => [qw/ cook tea --sugar /],
        stdout => qr/Starting to cook tea with sugar/,
    },
    {
        input => [qw/ cook tea --with /, "almond milk" ],
        stdout => qr/Starting to cook tea with almond milk/,
    },
    {
        input => [qw/ help /],
        stdout => qr/Usage: myapp <subcommands> \[options\]/,
    },
);

my @invalid = (
    {
        # missing parameter
        input => [qw/ cook /],
        eval_error => qr/drink.*missing/s,
        stderr => qr/Usage: myapp cook <drink> \[options\]/s,
    },
    {
        # invalid subcommand
        input => [qw/ foo /],
        eval_error => qr/Unknown subcommand 'foo'/s,
        stderr => qr/Usage: myapp <subcommands>/,
    },
    {
        input => [qw/ cook tea --with salt /],
        eval_error => qr/with.*invalid/s,
        stderr => qr/Usage: myapp cook <drink> \[options\]/,
    },
    {
        input => [qw/ /],
        eval_error => qr/Missing subcommand/s,
        stderr => qr/Usage: myapp <subcommands>/,
    },
);

my @completion = (
    {
        env => {
          PERL5_APPSPECRUN_COMPLETION_PARAMETER => "country",
          PERL5_APPSPECRUN_SHELL => 'zsh',
        },
        input => [qw/ weather show /],
        stdout => qr/Austria Germany Netherlands/,
    },
    {
        env => {
          PERL5_APPSPECRUN_COMPLETION_PARAMETER => "city",
          PERL5_APPSPECRUN_SHELL => 'zsh',
        },
        input => [qw/ weather show Netherlands /],
        stdout => qr/Amsterdam Echt/,
    },
);


subtest valid => sub {
    plan tests => scalar @valid * 2;
    for my $test (@valid) {
        my $input = $test->{input};
        my $stdout = $test->{stdout};

        my @cmd = ($^X, $app, @$input);
        my $ok = run \@cmd, \my $in, \my $out, \my $err, timeout( 10 );
        my $rc = $?;
        is($rc, 0, "args: (@$input) rc=0");
        cmp_ok($out, '=~', $stdout, "args: (@$input) output ok");
    }
};

subtest invalid => sub {
    plan tests => @invalid * 3;
    for my $test (@invalid) {
        my $input = $test->{input};
        my $stderr = $test->{stderr};
        my $exit = $test->{exit} || 255;
        my $eval_error = $test->{eval_error};

        my @cmd = ($^X, $app, @$input);
        my $ok = run \@cmd, \my $in, \my $out, \my $err, timeout( 10 );
        my $rc = $? >> 8;
        is($rc, $exit, "args: (@$input) rc=$exit");
        cmp_ok($err, '=~', $stderr, "args: (@$input) stderr ok");
        cmp_ok($err, '=~', $eval_error, "args: (@$input) stderr ok");
    }
};

subtest completion => sub {
    plan tests => scalar @completion * 2;
    for my $test (@completion) {
        my $env = $test->{env};
        local @ENV{ keys %$env } = values %$env;
        my $input = $test->{input};
        my $stdout = $test->{stdout};

        my @cmd = ($^X, $app, @$input);
        my $ok = run \@cmd, \my $in, \my $out, \my $err, timeout( 10 );
        my $rc = $?;
        is($rc, 0, "args: (@$input) rc=0");
        cmp_ok($out, '=~', $stdout, "args: (@$input) output ok");
    }
};
