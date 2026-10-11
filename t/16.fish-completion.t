use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use App::Spec;

my $fish_ok = do {
    my $v = `fish --version 2>/dev/null` // '';
    $v =~ m/version (\d+)/ and $1 >= 4;
};

my @apps = qw(nometa mysimpleapp myapp pcorelist subrepo);
for my $app (@apps) {
    my $spec = App::Spec->read("$Bin/../examples/$app-spec.yaml");
    my $file = "$Bin/../examples/fish/$app.fish";
    my $expected = do { open my $fh, '<', $file or die $!; local $/; <$fh> };
    my $completion = $spec->generate_completion(shell => 'fish');
    s/\s+\z// for $completion, $expected;
    cmp_ok $completion, 'eq', $expected, "fish completion for $app like expected";
    SKIP: {
        skip "fish >= 4.0 not available", 1 unless $fish_ok;
        is system(fish => -n => $file), 0, "fish -n $app.fish";
    }
}

done_testing;
