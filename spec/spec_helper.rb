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

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def trim_response(hash)
  result = {}
  hash.each do |k, v|
    case v
    when Hash
      result[k] = trim_response(v)
    when Array
      found = false
      v.reverse.each do |v2|
        if !v2.empty?
          found = true
        end
        if found
          result[k] ||= []
          result[k].unshift(trim_response(v2))
        end
      end
    else
      result[k] = v
    end
  end
  result
end

def load_orca_api_response_json(basename, trim = true)
  json_path = File.expand_path(File.join("../fixtures/orca_api_responses", basename), __FILE__)
  res = JSON.parse(File.read(json_path))
  if trim
    trim_response(res)
  else
    res
  end
end

def return_response_json(response_json)
  if response_json.is_a?(String)
    load_orca_api_response_json(response_json)
  else
    response_json
  end
end
