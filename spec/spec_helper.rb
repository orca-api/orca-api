require "bundler/setup"
if ENV["COVERAGE"] || ENV["CI"]
  require "simplecov"
  SimpleCov.coverage_dir(File.join(ENV["CIRCLE_ARTIFACTS"], "coverage")) if ENV["CIRCLE_ARTIFACTS"]
  SimpleCov.start do
    add_filter %w(/vendor/ /spec/)
  end
end
require "rspec/its"
require "webmock/rspec"
require "json"
require "pry-byebug"

require "orca_api"

require_relative "shared_examples"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def load_orca_api_response_json(basename)
  json_path = File.expand_path(File.join("../fixtures/orca_api_responses", basename), __FILE__)
  JSON.parse(File.read(json_path))
end
