use strict;
use warnings;
use Test::More;
use Test::Output;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec::Example::MyApp;
use App::Spec;
use IPC::Run qw( run timeout );
use YAML::XS qw/ Load /;
$ENV{PERL5_APPSPECRUN_COLOR} = 'never';
$ENV{PERL5_APPSPECRUN_TEST} = 1;
my $spec = App::Spec->read("$Bin/../examples/myapp-spec.yaml");
my $app = "$Bin/../examples/bin/myapp";

my $testdata = YAML::XS::LoadFile("$Bin/appspec-tests.yaml");

for my $test (@$testdata) {
    my $args = $test->{args};
    my $stdout = $test->{stdout} || [];
    my $stderr = $test->{stderr} || [];
    my $env = $test->{env};
    local %ENV = %ENV;
    if ($env) {
        @ENV{ keys %$env } = values %$env;
    }
    my $exit = $test->{exit};
    $stdout = [$stdout] unless ref $stdout eq 'ARRAY';
    $stderr = [$stderr] unless ref $stderr eq 'ARRAY';

    my @cmd = ($^X, $app, @$args);
    my $ok = run \@cmd, \my $in, \my $out, \my $err, timeout( 10 );
    my $rc = $? >> 8;
    is($rc, $exit, "args: (@$args) rc=$exit");
    for my $stdout (@$stdout) {
        cmp_ok($out, '=~', $stdout->{regex}, "args: (@$args) output ok");
    }
    for my $stderr (@$stderr) {
        cmp_ok($err, '=~', $stderr->{regex}, "args: (@$args) stderr ok");
    }
}

done_testing;
