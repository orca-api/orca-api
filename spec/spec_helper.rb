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
# 使用例を以下に示す。
# :bodyに指定するハッシュのキーに=を指定すると、値が完全に一致することをチェックできる。
# :bodyに指定するハッシュの値をバッククォートで括ると、そのバッククォートを取り除いた文字列に対して `context#eval` を呼び出した値を期待値とする。
# このとき、前回の結果はprevとして参照できる。
#
# ```ruby
# expect_data = [
#   {
#     path: "/api21/medicalmodv37",
#     body: {
#       "medicalv3req7" => {
#         "Request_Number" => "01",
#         "Karte_Uid" => orca_api.karte_uid,
#         "=Delete_Information" => {
#           "Delete_Karte_Uid" => "karte_uid",
#           "Delete_Orca_Uid" => "2204825e-c628-4747-8fc2-9e337b32125b",
#         },
#       }
#     },
#     result: "api21_medicalmodv37_01_one_S40.json",
#   },
#   {
#     path: "/api21/medicalmodv37",
#     body: {
#       "medicalv3req7" => {
#         "Request_Number" => "`prev.response_number`",
#         "Karte_Uid" => "`prev.karte_uid`",
#         "Orca_Uid" => "`prev.orca_uid`",
#         "=Delete_Information" => "`prev.delete_information`",
#         "Select_Answer" => "Ok",
#       }
#     },
#     result: "api21_medicalmodv37_01_one.json",
#   },
# ]
# expect_orca_api_call(expect_data, binding)
# ```
#
# @param [Array<Hash>] expect_data
#   以下の内容のハッシュの配列
#   * :path (String)
#     APIのエントリポイント
#   * :body (Hash)
#     リクエストボディに指定するハッシュ
#   * :response (String)
#     レスポンス。末尾が.jsonであればファイル名として扱い、ファイルの内容を読み込む。
# @param [Binding] context
#   呼び出し元のBindingオブジェクト。
def expect_orca_api_call(expect_data, context)
  count = 0
  expect(orca_api).to receive(:call).exactly(expect_data.length) do |path, body:|
    expect_datum = expect_data[count]
    if expect_datum.key?(:path)
      expect(path).to eq(expect_datum[:path])
    end

    if expect_datum.key?(:body)
      expect_orca_api_call_body(body, expect_datum[:body], context)
    end

    count += 1

    context.local_variable_set(:prev, nil)
    if expect_datum.key?(:response)
      return_response_json(expect_datum[:response])
    elsif expect_datum.key?(:result)
      res = OrcaApi::Result.new(return_response_json(expect_datum[:result]))
      context.local_variable_set(:prev, res)
      res.raw
    end
  end
end

# OrcaApi::OrcaApi#callのbody引数の内容をチェックする
#
# @param [Hash|Array|Object] actual_body
#   実際の値
# @param [Hash|Array|Object] expect_body
#   期待値
# @param [Object] context
#   呼び出し元のbinding
def expect_orca_api_call_body(actual_body, expect_body, context)
  case expect_body
  when Hash
    expect_body.each do |key, value|
      if (md = /\A=(.*)\z/.match(key))
        expect_orca_api_call_body_value(actual_body[md[1]], value, context)
      else
        expect_orca_api_call_body(actual_body[key], value, context)
      end
    end
  when Array
    expect_body.each.with_index do |value, index|
      expect_orca_api_call_body(actual_body[index], value, context)
    end
    expect(actual_body.length).to eq(expect_body.length)
  else
    expect_orca_api_call_body_value(actual_body, expect_body, context)
  end
end

# OrcaApi::OrcaApi#callのbody引数の値をチェックする
#
# 期待値がバッククォートで括ってあれば、それを取り除いてevalした値を期待値として扱う。
#
# @param [Object] actual_value
#   実際の値
# @param [Object] expect_value
#   期待値
# @param [Object] context
#   呼び出し元のbinding
def expect_orca_api_call_body_value(actual_value, expect_value, context)
  expect(actual_value).to eq(expect_orca_api_call_eval_value(expect_value, context))
end

# OrcaApi::OrcaApi#callのbody引数の期待値がバッククォートで括ってあれば、それを取り除いてevalした値を期待値として返す
#
# @param [Object] expect_value
#   期待値
# @param [Object] context
#   呼び出し元のbinding
# @return [Object] 必要であればevalした期待値
def expect_orca_api_call_eval_value(expect_value, context)
  case expect_value
  when String
    if (md = /\A`(.*)`\z/.match(expect_value))
      context.eval(md[1])
    else
      expect_value
    end
  when Hash
    res = {}
    expect_value.each do |key, val|
      res[key] = expect_orca_api_call_eval_value(val, context)
    end
    res
  else
    expect_value
  end
end
