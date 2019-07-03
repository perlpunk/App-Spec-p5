use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use App::Spec;
use App::Spec::Example::Nometa;
use Data::Dumper;

my $specfile = "$Bin/../examples/nometa-spec.yaml";

subtest nometa_valid => sub {
    my $spec = App::Spec->read($specfile);
    my $runner = $spec->runner;
    $runner->response->buffered(1);
    {
        local @ARGV = qw/ foo a /;
        $runner->process;
    };
    my $res = $runner->response;
    my $outputs = $res->outputs;
    cmp_ok(scalar @$outputs, '==', 1, "Output number ok");
    my $output = $outputs->[0];
    cmp_ok($output->content, 'eq', "foo\n", "Output ok");
};

subtest nometa_invalid => sub {
    my $spec = App::Spec->read($specfile);
    my $runner = $spec->runner;
    $runner->response->buffered(1);
    {
        local @ARGV = qw/ _meta /;
        $runner->process;
    };
    my $res = $runner->response;
    my $outputs = $res->outputs;
    my $output = $outputs->[1];
    cmp_ok($output->content, '=~', qr{Unknown subcommand}, "Output error as expected");
};

done_testing;
