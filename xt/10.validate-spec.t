use strict;
use warnings;
use Test::More tests => 3;
use FindBin '$Bin';
my $v = eval "use App::AppSpec::Schema::Validator; 1";
SKIP: {
    skip "App::AppSpec::Schema::Validator not installed", 3 unless $v;
    my $validator = App::AppSpec::Schema::Validator->new;
    my @files = qw/ myapp-spec.yaml subrepo-spec.yaml pcorelist-spec.yaml /;

    for my $file (@files) {
        my $path = "$Bin/../examples/$file";
        my @errors = $validator->validate_spec_file($path);
        is(scalar @errors, 0, "spec $file is valid");
        if (@errors) {
            diag $validator->format_errors(\@errors);
        }
    }
}
