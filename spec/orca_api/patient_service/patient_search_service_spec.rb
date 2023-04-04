require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::PatientSearchService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#search" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path|
        expect(path).to eq("/api01rv2/patientlst3v2?class=01")
        response_json
      end
    end

    subject { service.search(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("api01rv2_patientlst3v2.json") }
      let(:args) do
        {
          WholeName: "テスト　社保"
        }
      end

      its("ok?") { is_expected.to be(true) }
    end
  end
end
