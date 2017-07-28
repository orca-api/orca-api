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
  let(:options) { ["example.com", double("authentication"), 18000] }
  let(:orca_api) { OrcaApi::OrcaApi.new(*options) }

  describe ".new" do
    subject { orca_api }

    its(:host) { is_expected.to eq(options[0]) }
    its(:authentication) { is_expected.to eq(options[1]) }
    its(:port) { is_expected.to eq(options[2]) }

    describe "portは省略可能" do
      let(:options) { ["example.com", double("authentication")] }

      its(:port) { is_expected.to eq(8000) }
    end
  end

  describe "#karte_uid" do
    subject { orca_api.karte_uid }

    context "karte_uidを設定済み" do
      before do
        orca_api.karte_uid = "user_specified_karte_uid"
      end

      it { is_expected.to eq("user_specified_karte_uid") }
    end

    context "karte_uidを未設定" do
      it "SecureRandom.uuidを使ってkarte_uidを自動生成すること" do
        expect(SecureRandom).to receive(:uuid).and_return("generated uuid").once
        is_expected.to eq("generated uuid")
      end
    end
  end

  describe "#debug_ouput=" do
    let(:http) { spy("Net::HTTP") }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      orca_api = OrcaApi::OrcaApi.new("example.com", spy("authentication"))
      orca_api.debug_output = $stdout
      orca_api.call("/path/to/api")
    end

    it { expect(http).to have_received(:set_debug_output).with($stdout) }
  end

  describe "#call" do
    shared_examples "日レセAPIを呼び出せること" do
      let(:options) { ["example.com", authentication, 18000] }
      let(:url) { "#{http_scheme}://#{options[0]}:#{options[2]}" }
      let(:result) {
        load_orca_api_response_json(path[1..-1].gsub("/", "_") + ".json")
      }

      subject {
        orca_api.call(path, params: params, body: body, http_method: http_method)
      }

      before do
        query = params.merge(format: "json").map { |k, v| "#{k}=#{v}" }.join("&")
        stub_request(http_method, URI.join(url, path, "?#{query}"))
          .with(body: body ? body.to_json : nil)
          .to_return(body: result.to_json)
      end

      describe "/api01rv2/patientgetv2" do
        let(:path) { "/api01rv2/patientgetv2" }
        let(:params) {
          { id: "1" }
        }
        let(:body) { nil }
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

    context "BASIC認証" do
      let(:authentication) { OrcaApi::OrcaApi::BasicAuthentication.new("ormaster", "ormaster") }
      let(:http_scheme) { "http" }

      include_examples "日レセAPIを呼び出せること"
    end

    context "SSLクライアント認証+BASIC認証" do
      let(:authentication) {
        ssl_auth = OrcaApi::OrcaApi::SslClientAuthentication.new("ca_file", "cert_path", "key_path")
        allow(ssl_auth).to receive(:cert).and_return("cert")
        allow(ssl_auth).to receive(:key).and_return("key")
        expect(ssl_auth).to receive(:apply).once.and_call_original

        basic_auth = OrcaApi::OrcaApi::BasicAuthentication.new("ormaster", "ormaster")
        expect(basic_auth).to receive(:apply).once.and_call_original

        [ssl_auth, basic_auth]
      }
      let(:http_scheme) { "https" }

      include_examples "日レセAPIを呼び出せること"
    end

    context "bodyにハッシュ以外のオブジェクトを指定する" do
      # HACK: spyにはもともとto_jsonというメソッドが定義されているため、明示的に指定する必要がある
      let(:body) { spy("body", to_json: "json") }

      before do
        allow(Net::HTTP).to receive(:new).and_return(spy("Net::HTTP"))
        orca_api = OrcaApi::OrcaApi.new("example.com", [])
        orca_api.call("/path/to/api", body: body)
      end

      it { expect(body).to have_received(:to_json) }
    end
  end

  describe "#new_patient_service" do
    subject { orca_api.new_patient_service }

    it { is_expected.to be_instance_of(OrcaApi::PatientService) }
    its(:orca_api) { is_expected.to eq(orca_api) }
  end

  describe "#new_insurance_service" do
    subject { orca_api.new_insurance_service }

    it { is_expected.to be_instance_of(OrcaApi::InsuranceService) }
    its(:orca_api) { is_expected.to eq(orca_api) }
  end
end
