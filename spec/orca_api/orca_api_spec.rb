# coding: utf-8

require "spec_helper"

# 日レセAPIの実行結果のうち、実行日時のような実行時に決定する値以外が等しいかどうかを検証する
RSpec::Matchers.define :be_api_result_equal_to do |expected|
  exclude_keys = %w(
    Information_Date
    Information_Time
  )
  match do |actual|
    response_name = expected.keys.first
    exclude_keys.each do |k|
      expected[response_name][k] = actual[response_name][k]
    end
    actual == expected
  end

  diffable
end

RSpec.describe OrcaApi::OrcaApi do
  # HACK: 環境変数ORCA_API_URLに日レセのURLを指定すると、実際に日レセAPIを呼び出してレスポンスを出力する。
  #   そのとき、環境変数ORCA_API_BASIC_AUTHENTICATIONに「<ユーザ名>/<パスワード>」の形式でBASIC認証の認証情報を指定できる。
  let(:orca_api_options) {
    {
      url: ENV["ORCA_API_URL"] || "http://example.com:8000",
      basic_authentication:
        ENV["ORCA_API_BASIC_AUTHENTICATION"] ? ENV["ORCA_API_BASIC_AUTHENTICATION"].split("/") : %w(ormaster ormaster),
      debug_output: $stdout,
    }
  }
  let(:orca_api) { OrcaApi::OrcaApi.new(orca_api_options) }

  describe "#url" do
    subject { orca_api.url }
    it { is_expected.to eq(orca_api_options[:url]) }
  end

  describe "#basic_authentication" do
    subject { orca_api.basic_authentication }
    it { is_expected.to eq(orca_api_options[:basic_authentication]) }
  end

  describe "#call" do
    let(:result) {
      fixture_name = path[1..-1].gsub("/", "_") + ".json"
      fixture_path = File.expand_path(File.join("../../fixtures/orca_api_results", fixture_name), __FILE__)
      eval(File.read(fixture_path))
    }

    subject {
      json = orca_api.call(path, params: params, body: body, http_method: http_method)
      # HACK: レスポンスを整形して出力する
      if ENV["ORCA_API_URL"]
        $stderr.puts(json.ai)
      end
      json
    }

    before do
      query = params.merge(format: "json").map { |k, v| "#{k}=#{v}" }.join("&")
      stub_request(http_method, URI.join(orca_api_options[:url], path, "?#{query}"))
        .with(body: body.empty? ? nil : body.to_json)
        .to_return(body: result.to_json)
    end

    # HACK: 実際のサーバにリクエストを送信する
    if ENV["ORCA_API_URL"]
      before { WebMock.disable! }
    end

    describe "/api01rv2/patientgetv2" do
      let(:path) { "/api01rv2/patientgetv2" }
      let(:params) {
        { id: "1" }
      }
      let(:body) {
        {}
      }
      let(:http_method) { :get }

      it { is_expected.to be_api_result_equal_to(result) }
    end

    describe "/api01rv2/patientlst1v2" do
      let(:path) { "/api01rv2/patientlst1v2" }
      let(:params) {
        { "class" => "01" }
      }
      let(:body) {
        {
          "patientlst1req" => {
            "Base_StartDate" => "2012-06-01",
            "Base_EndDate" => "2012-06-30",
            "Contain_TestPatient_Flag" => 1,
          }
        }
      }
      let(:http_method) { :post }

      it { is_expected.to be_api_result_equal_to(result) }
    end
  end
end
