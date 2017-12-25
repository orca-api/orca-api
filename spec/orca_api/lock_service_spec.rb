require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::LockService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#list" do
    subject { service.list }

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).exactly(1) { |path, body:|
        count += 1
        prev_response_json =
          case count
          when 1
            expect(path).to eq("/api21/medicalmodv37")

            req = body["medicalv3req7"]
            expect(req["Request_Number"]).to eq("00")
            expect(req["Karte_Uid"]).to eq(orca_api.karte_uid)

            response_json
          end
        prev_response_json
      }
    end

    context "排他中" do
      let(:response_json) { load_orca_api_response("api21_medicalmodv37_00.json") }

      its("ok?") { is_expected.to be true }
      %w(
        Lock_Information
      ).each do |name|
        its([name]) { is_expected.to eq(response_data.first[1][name]) }
      end
    end

    context "排他中ではない" do
      let(:response_json) { load_orca_api_response("api21_medicalmodv37_00_E10.json") }

      its("ok?") { is_expected.to be false }
    end
  end
end
