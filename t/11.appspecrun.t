use strict;
use warnings;
use Test::More;
use Test::Trap;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec::Example::MyApp;
use App::Spec::Example::MySimpleApp;
use App::Spec;
use YAML::XS ();
$ENV{PERL5_APPSPECRUN_COLOR} = 'never';
$ENV{PERL5_APPSPECRUN_TEST} = 1;

my $testdata = YAML::XS::LoadFile("$Bin/appspec-tests.yaml");

for my $test (@$testdata) {
    my $args = $test->{args};
    my $app = shift @$args;
    my $spec = App::Spec->read("$Bin/../examples/$app-spec.yaml");
    my $runner = $spec->runner;
    my $exit = $test->{exit};
    my $env = $test->{env};
    my $name = "args: (@$args)";
    $name .= ", $_=$env->{$_}" for sort keys %$env;

    subtest $name => sub {
        my @r = trap {
            local @ARGV = @$args;
            local %ENV = %ENV;
            if ($env) {
                @ENV{ keys %$env } = values %$env;
            }
            $runner->run;
        };
        ok ( defined $trap->die, "Expecting to exit with $exit" ) if $exit;
        my $stdout = $test->{stdout} || [];
        my $stderr = $test->{stderr} || [];
        $stdout = [$stdout] unless ref $stdout eq 'ARRAY';
        $stderr = [$stderr] unless ref $stderr eq 'ARRAY';
        for my $item (@$stdout) {
            my $regex = $item->{regex};
            like ( $trap->stdout, qr{$regex}, "Expecting STDOUT: $regex" );
        }
        my $err = ($trap->die // '') . ($trap->stderr // '');
        for my $item (@$stderr) {
            my $regex = $item->{regex};
            like ( $err, qr{$regex}, "Expecting STDERR: $regex" );
        }
    };
}

done_testing;
