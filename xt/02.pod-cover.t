use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => 8;
my $xsaccessor = eval "use Class::XSAccessor; 1";
unless ($xsaccessor) {
    diag "\n----------------";
    diag "Class::XSAccessor is not installed. Class attributes might not be checked";
    diag "----------------";
}
pod_coverage_ok("App::Spec");
pod_coverage_ok("App::Spec::Option");
pod_coverage_ok("App::Spec::Parameter");
pod_coverage_ok("App::Spec::Argument");
pod_coverage_ok("App::Spec::Run");
pod_coverage_ok("App::Spec::Completion");
pod_coverage_ok("App::Spec::Completion::Bash");
pod_coverage_ok("App::Spec::Completion::Zsh");
# TODO
#all_pod_coverage_ok();
