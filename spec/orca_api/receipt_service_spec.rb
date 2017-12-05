require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::ReceiptService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json, false) }

  describe "#create" do
    let(:args) {
      {
        "Perform_Date" => "",
        "Perform_Month" => "2017-11",
        "InOut" => "O",
        "Receipt_Mode" => "All",
        "Print_Mode" => "Check",
        "Submission_Mode" => "02",
        "Patient_Information" => [],
      }
    }

    subject { service.create(args) }

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).exactly(1) { |path, body:|
        count += 1
        prev_response_json =
          case count
          when 1
            aggregate_failures "リクエスト内容のチェック" do
              expect(path).to eq("/orca42/receiptmakev3")

              req = body["receipt_makev3req"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq(orca_api.karte_uid)
              expect(req["Orca_Uid"]).to eq("")
              %w(
                Perform_Date
                Perform_Month
                InOut
                Receipt_Mode
                Print_Mode
                Submission_Mode
                Patient_Information
              ).each do |name|
                expect(req[name]).to eq(args[name])
              end
            end

            response_json
          end
        prev_response_json
      }
    end

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca42_receiptmakev3_01.json") }

      its("ok?") { is_expected.to be(true) }
      its(["Response_Number"]) { is_expected.to eq("02") }
      its(["Orca_Uid"]) { is_expected.to eq("c585dc3e-fa42-4f45-b02f-5a4166d0721d") }
    end

    context "異常系" do
      let(:response_json) { load_orca_api_response("orca42_receiptmakev3_01_E13.json") }

      its("ok?") { is_expected.to be(false) }
    end
  end
end
