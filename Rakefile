require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--format documentation --format RspecJunitFormatter --out $CIRCLE_TEST_REPORTS/rspec.xml" if ENV.key? "CI"
end

RuboCop::RakeTask.new do |t|
  if ENV.key?("CI")
    require "rubocop"
    require "rubocop/formatter/junit_formatter"
    t.formatters = ["RuboCop::Formatter::JUnitFormatter"]
    t.options = ["--out", File.join(ENV["CIRCLE_TEST_REPORTS"], "rubocop.xml")]
  end
end

task default: [:spec, :rubocop]
