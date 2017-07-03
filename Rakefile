require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--format documentation --format RspecJunitFormatter --out $CIRCLE_TEST_REPORTS/rspec.xml" if ENV.key? "CI"
end

task :default => :spec
