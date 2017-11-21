require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::FormDataService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json, false) }

  describe "#get" do
    let(:data_id) { SecureRandom.hex }

    subject { service.get data_id }

    before do
      expect(orca_api).to receive(:call).with("/api01rv2/formdatagetv2",
                                              body: { "data" => { "Data_ID" => data_id } }).once.and_return(response_json)
    end

    context "正常系" do
      let(:response_json) { load_orca_api_response("api01rv2_formdatagetv2.json") }

      its("ok?") { is_expected.to be true }
      its("forms") { is_expected.to eq response_data["Forms"] }
    end

    context "エラーレスポンスの場合" do
      let(:response_json) { load_orca_api_response("api01rv2_formdatagetv2_0001.json") }

      its("ok?") { is_expected.to be false }
    end
  end
end
