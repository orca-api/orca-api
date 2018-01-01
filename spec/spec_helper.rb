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

def load_orca_api_response(basename)
  path = File.expand_path(File.join("fixtures/orca_api_responses", basename), __dir__)
  File.read(path)
end

def parse_json(raw, trim = true)
  res = JSON.parse(raw)
  if trim
    trim_response(res)
  else
    res
  end
end

def return_response_json(response_json)
  if /.json$/ =~ response_json
    load_orca_api_response(response_json)
  else
    response_json
  end
end

# OrcaApi::OrcaApi#callの呼び出し回数と引数をチェックする
#
# @param [Array<Hash>] expect_data
#   以下の内容のハッシュの配列
#   * :path (String)
#     APIのエントリポイント
#   * :body (Hash)
#     リクエストボディに指定するハッシュ
#   * :response (String)
#     レスポンス。末尾が.jsonであればファイル名として扱い、ファイルの内容を読み込む。
def expect_orca_api_call(expect_data)
  count = 0
  prev_response = nil
  expect(orca_api).to receive(:call).exactly(expect_data.length) do |path, body:|
    expect_datum = expect_data[count]
    if expect_datum.key?(:path)
      expect(path).to eq(expect_datum[:path])
    end
    if expect_datum.key?(:body)
      expect_orca_api_call_body(body, expect_datum[:body])
    end
    if expect_datum.key?(:response)
      prev_response = return_response_json(expect_datum[:response])
    end
    count += 1
    prev_response
  end
end

# OrcaApi::OrcaApi#callのbody引数の内容をチェックする
#
# @param [Hash|Array|Object] actual_body
#   実際の値
# @param [Hash|Array|Object] expect_body
#   期待値
def expect_orca_api_call_body(actual_body, expect_body)
  case expect_body
  when Hash
    expect_body.each do |key, value|
      if (md = /\A=(.*)\z/.match(key))
        expect(actual_body[md[1]]).to eq(value)
      else
        expect_orca_api_call_body(actual_body[key], value)
      end
    end
  when Array
    expect_body.each.with_index do |value, index|
      expect_orca_api_call_body(actual_body[index], value)
    end
    expect(actual_body.length).to eq(expect_body.length)
  else
    expect(actual_body).to eq(expect_body)
  end
end
