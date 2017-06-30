require "bundler/setup"
if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start
end
require "rspec/its"
require "webmock/rspec"
require "awesome_print"
AwesomePrint.defaults = {
  indent: 2,
  index: false,
  plain: true,
}

require "orca_api"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
