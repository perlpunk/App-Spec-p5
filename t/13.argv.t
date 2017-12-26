use strict;
use warnings;
use Test::More tests => 3;
use Test::Deep;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec::Example::MyApp;
use App::Spec;
$ENV{PERL5_APPSPECRUN_COLOR} = 'never';
$ENV{PERL5_APPSPECRUN_TEST} = 1;

{
    my $spec = App::Spec->read("$Bin/../examples/myapp-spec.yaml");
    my @args = qw/ help convert /;

    my $runner1 = $spec->runner;
    {
        local @ARGV = @args;
        $runner1->process;
    };

    my $runner2 = $spec->runner(
        argv => [@args],
    );
    $runner2->process;

    my $res1 = $runner1->response;
    my $res2 = $runner2->response;
    # we don't care about the callbacks here
    $_->callbacks({}) for ($res1, $res2);
    cmp_deeply(
        $res1,
        $res2,
        "response is the same for default and custom \@ARGV",
        );

    cmp_deeply(
        $runner1->argv_orig,
        [@args],
        "argv_orig() correct",
    );
    cmp_deeply(
        $runner1->argv,
        [],
        "argv() empty",
    );
}

done_testing;
