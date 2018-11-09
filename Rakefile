require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop"
require "rubocop/rake_task"
require "rubocop/formatter/junit_formatter"
require "yard"

RSpec::Core::RakeTask.new(:spec) do |t|
  if ENV.key? "CIRCLE_TEST_REPORTS"
    out = File.join(ENV["CIRCLE_TEST_REPORTS"], "rspec.xml")
    t.rspec_opts = "--format documentation --format RspecJunitFormatter --out #{out}"
  end
end

RuboCop::RakeTask.new do |t|
  t.options = ["--parallel", "--config", File.expand_path(".rubocop.yml", __dir__)]
  if ENV.key? "CIRCLE_TEST_REPORTS"
    t.formatters = ["progress", "RuboCop::Formatter::JUnitFormatter"]
    out = File.join(ENV["CIRCLE_TEST_REPORTS"], "rubocop.xml")
    t.options.push "--out", out
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
  t.stats_options = ["--list-undoc", "--compact"]
  output_dir = if ENV.key? "CIRCLE_ARTIFACTS"
                 File.join(ENV["CIRCLE_ARTIFACTS"], "docs")
               else
                 "docs"
               end
  t.options = ["--no-progress",
               "--output-dir", output_dir,
               "--template", "default",
               "--template-path", File.expand_path("templates", File.dirname(__FILE__))]
end

namespace :version do
  desc "Bump the patch version"
  task :bump do
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
end

task default: [:spec, :rubocop]
