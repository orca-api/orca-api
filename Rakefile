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
    t.formatters = ["progress", "RuboCop::Formatter::JUnitFormatter"]
    t.options = ["--out", File.join(ENV["CIRCLE_TEST_REPORTS"], "rubocop", "rubocop.xml")]
  end
end

task :bump_up_version do
  path = "lib/orca_api/version.rb"
  load(File.expand_path(path, __dir__))
  next_version = OrcaApi::VERSION.split('.').tap { |versions|
    versions[-1] = (versions[-1].to_i + 1).to_s
  }.join('.')

  File.open(path, 'r+') do |f|
    lines = []
    while (line = f.gets)
      if (md = /(\s*VERSION =\s*)/.match(line))
        line = %'#{md[1]}"#{next_version}".freeze\n'
      end
      lines << line
    end
    f.rewind
    f.write(lines.join)
  end
  sh "git add #{path}"
  sh "git commit -m 'bump up version #{next_version}.'"
end

task default: [:spec, :rubocop]
