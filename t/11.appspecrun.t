use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec::Example::MyApp;
use App::Spec::Example::MySimpleApp;
use App::Spec;
use YAML::XS ();
$ENV{PERL5_APPSPECRUN_COLOR} = 'never';
$ENV{PERL5_APPSPECRUN_TEST} = 1;

my @datafiles = map {
    "$Bin/data/$_"
} qw/ 11.completion.yaml 11.invalid.yaml 11.valid.yaml /;
my @testdata = map { my $d = YAML::XS::LoadFile($_); @$d } @datafiles;

for my $test (@testdata) {
    my $args = $test->{args};
    my $app = shift @$args;
    my $spec = App::Spec->read("$Bin/../examples/$app-spec.yaml");
    my $runner = $spec->runner;
    my $exit = $test->{exit} || 0;
    my $env = $test->{env};
    my $name = "$app args: (@$args)";
    $name .= ", $_=$env->{$_}" for sort keys %$env;

    subtest $name => sub {
        {
            local @ARGV = @$args;
            local %ENV = %ENV;
            if ($env) {
                @ENV{ keys %$env } = values %$env;
            }
            $runner->process;
        };
        my $res = $runner->response;
        my $outputs = $res->outputs;
        my @stdout_output = map { $_->content } grep { not $_->error } @$outputs;
        my @stderr_output = map { $_->content } grep { $_->error } @$outputs;

        my $res_exit = $res->exit;
        cmp_ok ( $res_exit, '==', $exit, "Expecting to exit with $exit" );

        my $stdout = $test->{stdout} || [];
        my $stderr = $test->{stderr} || [];
        $stdout = [$stdout] unless ref $stdout eq 'ARRAY';
        $stderr = [$stderr] unless ref $stderr eq 'ARRAY';

        for my $item (@$stdout) {
            my $regex = $item->{regex};
            like ( "@stdout_output", qr{$regex}, "Expecting STDOUT: $regex" );
        }
        for my $item (@$stderr) {
            my $regex = $item->{regex};
            like ( "@stderr_output", qr{$regex}, "Expecting STDERR: $regex" );
        }
    };
}

done_testing;
