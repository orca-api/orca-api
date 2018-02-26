require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::ReceiptDataService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list_effective_information" do
    context "正常系" do
      it "医保分のレセ電データ作成時に必要な情報取得できること" do
        perform_month = "208-02"
        submission_mode = "02"
        now = Time.now

        expect_data = [
          {
            path: "/orca44/receiptdatamakev3",
            body: {
              "=receiptdata_makev3req" => {
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
                "Perform_Month" => perform_month,
                "Submission_Mode" => submission_mode,
                "Perform_Date" => now.strftime("%Y-%m"),
                "Ac_Date" => now.strftime("%Y-%m-%d"),
                "Receipt_Mode" => "02",
                "InOut" => "IO",
                "Check_Mode" => "",
              }
            },
            result: "orca44_receiptdatamakev3_00.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        Timecop.freeze(now) do
          result = service.list_effective_information(perform_month, submission_mode)
          expect(result.ok?).to be true
        end
      end

      it "該当する情報がない場合は空の配列を返すこと" do
        perform_month = "208-01"
        submission_mode = "02"
        now = Time.now

        expect_data = [
          {
            path: "/orca44/receiptdatamakev3",
            body: {
              "=receiptdata_makev3req" => {
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
                "Perform_Month" => perform_month,
                "Submission_Mode" => submission_mode,
                "Perform_Date" => now.strftime("%Y-%m"),
                "Ac_Date" => now.strftime("%Y-%m-%d"),
                "Receipt_Mode" => "02",
                "InOut" => "IO",
                "Check_Mode" => "",
              }
            },
            result: "orca44_receiptdatamakev3_00_empty.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        Timecop.freeze(now) do
          result = service.list_effective_information(perform_month, submission_mode)
          expect(result.ok?).to be true
          expect(result["Effective_Period_Information"]).to eq([])
          expect(result.effective_period_information).to eq([])
          expect(result["Effective_InsuranceProvider_Information"]).to eq([])
          expect(result.effective_insurance_provider_information).to eq([])
        end
      end
    end

    context "異常系" do
      it "提出先の設定に誤りがある場合はエラー" do
        perform_month = "208-01"
        submission_mode = "01"
        now = Time.now

        expect_data = [
          {
            path: "/orca44/receiptdatamakev3",
            body: {
              "=receiptdata_makev3req" => {
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
                "Perform_Month" => perform_month,
                "Submission_Mode" => submission_mode,
                "Perform_Date" => now.strftime("%Y-%m"),
                "Ac_Date" => now.strftime("%Y-%m-%d"),
                "Receipt_Mode" => "02",
                "InOut" => "IO",
                "Check_Mode" => "",
              }
            },
            result: "orca44_receiptdatamakev3_00_E13.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        Timecop.freeze(now) do
          result = service.list_effective_information(perform_month, submission_mode)
          expect(result.ok?).to be false
        end
      end
    end
  end
end
