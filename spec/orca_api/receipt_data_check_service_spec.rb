require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::ReceiptDataCheckService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:now) { Time.now }

  def default_request
    {
      "Perform_Date" => now.strftime("%Y-%m-%d"),
      "Perform_Month" => now.strftime("%Y-%m"),
      "Ac_Date" => now.strftime("%Y-%m-%d"),
      "Create_Mode" => "Check",
      "InOut" => "IO",
      "Check_Mode" => "No",
    }
  end

  describe "#list_effective_information" do
    context "正常系" do
      it "医保分のレセ電データ作成時に必要な情報取得できること" do
        perform_month = "2019-03"
        submission_mode = "02"

        expect_data = [
          {
            path: "/orca44/receiptdatacheckmakev3",
            body: {
              "=receiptdata_check_makev3req" => default_request.merge(
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
                "Perform_Month" => perform_month,
                "Submission_Mode" => submission_mode,
                "InOut" => "IO"
              )
            },
            result: "orca44_receiptdatacheckmakev3_00.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        Timecop.freeze(now) do
          result = service.list_effective_information({
                                                        "Perform_Month" => perform_month,
                                                        "Submission_Mode" => submission_mode
                                                      })
          expect(result.ok?).to be true
        end
      end

      it "該当する情報がない場合は空の配列を返すこと" do
        perform_month = "2019-03"
        submission_mode = "02"

        expect_data = [
          {
            path: "/orca44/receiptdatacheckmakev3",
            body: {
              "=receiptdata_check_makev3req" => default_request.merge(
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
                "Perform_Month" => perform_month,
                "Submission_Mode" => submission_mode,
                "InOut" => "IO"
              )
            },
            result: "orca44_receiptdatacheckmakev3_00_empty.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        Timecop.freeze(now) do
          result = service.list_effective_information({
                                                        "Perform_Month" => perform_month,
                                                        "Submission_Mode" => submission_mode
                                                      })
          expect(result.ok?).to be true
          expect(result["Effective_Period_Information"]).to eq([])
          expect(result.effective_period_information).to eq([])
          expect(result["InsuranceProvider_Information"]).to eq([])
          expect(result.insurance_provider_information).to eq([])
        end
      end
    end
  end

  describe "チェック用個別レセ電データ取得" do
    context "正常系" do
      it "レセ電データのUIDを取得できること" do
        args = {
          "Perform_Month" => "2019-03",
          "Submission_Mode" => "02",
        }

        expect_data = [
          {
            path: "/orca44/receiptdatacheckmakev3",
            body: {
              "=receiptdata_check_makev3req" => default_request.merge(args).merge(
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid
              ),
            },
            result: "orca44_receiptdatacheckmakev3_01.json",
          },
          {
            path: "/orca44/receiptdatacheckmakev3",
            body: {
              "=receiptdata_check_makev3req" => default_request.merge(args).merge(
                "Request_Number" => "02",
                "Karte_Uid" => orca_api.karte_uid,
                "Orca_Uid" => "`prev.orca_uid`"
              ),
            },
            result: "orca44_receiptdatacheckmakev3_02_E70.json",
          },
          {
            path: "/orca44/receiptdatacheckmakev3",
            body: {
              "=receiptdata_check_makev3req" => default_request.merge(args).merge(
                "Request_Number" => "02",
                "Karte_Uid" => orca_api.karte_uid,
                "Orca_Uid" => "`prev.orca_uid`"
              ),
            },
            result: "orca44_receiptdatacheckmakev3_02.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        Timecop.freeze(now) do
          result = service.create(args)
          expect(result.ok?).to be true

          data = parse_json(load_orca_api_response("orca44_receiptdatacheckmakev3_01.json"))
          expect(result["Data_Id_Information"]).to eq data.first[1]["Data_Id_Information"]

          args["Orca_Uid"] = result.orca_uid
          result = service.created(args)
          expect(result.doing?).to be true
          expect(result.ok?).to be false

          result = service.created(args)
          expect(result.doing?).to be false
          expect(result.ok?).to be true
        end
      end
    end
  end
end
