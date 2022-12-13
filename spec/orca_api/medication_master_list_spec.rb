require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::MedicationMasterListService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#list" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path|
        expect(path).to eq("/orca51/medicationmasterlstv3")
        response_json
      end
    end

    subject { service.list(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca51_medicationmasterlstv3_01.json") }
      let(:args) do
        {
          Request_Number: "01",
          Karte_Uid: "94e16fd4-4664-49cf-9be0-0af44ac25d4a",
          Orca_Uid: "060e7c98-2dab-438d-bd6f-18a58c55a1fe",
          Base_Date: "2022-10-10",
          Effective_Mode: "csv",
        }

        its("ok?") { is_expected.to be(true) }
      end
    end

    context "異常系" do
      let(:response_json) { load_orca_api_response("orca51_medicationmasterlstv3_01_E04.json") }
      let(:args) { {} }

      its("ok?") { is_expected.to be(false) }
    end
  end
end