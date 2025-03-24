use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec;
use App::Spec::Pod;

my @apps = qw(nometa mysimpleapp myapp pcorelist);
for my $app (@apps) {
    my $spec = App::Spec->read("$Bin/../examples/$app-spec.yaml");
    my $podfile = "$Bin/../examples/pod/$app.pod";
    my $podexpected = do { open my $fh, '<', $podfile; local $/; <$fh> };
    my $generator = App::Spec::Pod->new(
        spec => $spec,
    );
    my $pod = $generator->generate;
    s/\s+\z// for $pod, $podexpected;
    cmp_ok $pod, 'eq', $podexpected, "Pod for $app like expected";
}

done_testing;
