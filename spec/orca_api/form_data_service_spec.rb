require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::FormDataService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    let(:data_id) { SecureRandom.hex }

    context "正しいData IDを指定した場合" do
      let(:response_json) { load_orca_api_response_json("api01rv2_formdatagetv2_00.json", false) }

      before do
        expect(orca_api).to receive(:call).with("/api01rv2/formdatagetv2",
                                                body: { "data" => { "Data_ID" => data_id } }).once.and_return(response_json)
      end

      subject { service.get data_id }

      its("ok?") { is_expected.to be true }
      its("forms") { is_expected.to_not be_empty }
    end

    context "不正なData IDを指定した場合" do
      let(:response_json) { load_orca_api_response_json("api01rv2_formdatagetv2_01.json", false) }

      before do
        expect(orca_api).to receive(:call).with("/api01rv2/formdatagetv2",
                                                body: { "data" => { "Data_ID" => data_id } }).once.and_return(response_json)
      end

      subject { service.get data_id }

      its("ok?") { is_expected.to be false }
    end
  end
end
