use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
plan tests => 4;
pod_coverage_ok("App::Spec");
pod_coverage_ok("App::Spec::Option");
pod_coverage_ok("App::Spec::Parameter");
pod_coverage_ok("App::Spec::Argument");
#pod_coverage_ok("App::Spec::Run");
# TODO
#all_pod_coverage_ok();
