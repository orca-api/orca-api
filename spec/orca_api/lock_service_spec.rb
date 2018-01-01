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

  describe "#unlock_all" do
    context "排他中" do
      it "すべての排他制御を解除する" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => "karte_uid",
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
              }
            },
            response: "api21_medicalmodv37_01_all_S40.json",
          },
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => "karte_uid",
                "Orca_Uid" => "c585dc3e-fa42-4f45-b02f-5a4166d0721d",
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
                "Select_Answer" => "Ok",
              }
            },
            response: "api21_medicalmodv37_01_all.json",
          },
        ]
        expect_orca_api_call(expect_data)

        result = service.unlock_all

        expect(result.ok?).to be true
      end
    end

    context "排他中ではない" do
      it "排他制御を解除するための日レセAPIを呼び出す" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => "karte_uid",
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
              }
            },
            response: "api21_medicalmodv37_01_all_S40_empty.json",
          },
          {
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => "karte_uid",
                "Orca_Uid" => "c585dc3e-fa42-4f45-b02f-5a4166d0721d",
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
                "Select_Answer" => "Ok",
              }
            },
            response: "api21_medicalmodv37_01_all.json",
          },
        ]
        expect_orca_api_call(expect_data)

        result = service.unlock_all

        expect(result.ok?).to be true
      end
    end
  end
end
