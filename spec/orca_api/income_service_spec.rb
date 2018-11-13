require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::IncomeService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  def expect_orca23_incomev3_01(path, body, mode, args, response_json)
    expect(path).to eq(OrcaApi::IncomeService::PATH)

    req = body[OrcaApi::IncomeService::REQUEST_NAME]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Request_Mode"]).to eq(mode)
    expect(req["Karte_Uid"]).to eq(orca_api.karte_uid)
    expect(req["Orca_Uid"]).to be_nil

    attr_names = case mode
                 when "01"
                   %w(
                     Patient_ID
                     Information_Class
                     Start_Date
                     End_Date
                     Start_Month
                     End_Month
                     Sort_Key
                   )
                 when "02"
                   %w(
                     Patient_ID
                     InOut
                     Invoice_Number
                   )
                 else
                   raise "invalid mode: #{mode}"
                 end
    attr_names.each do |attr_name|
      expect(req[attr_name]).to eq(args[attr_name])
    end

    return_response_json(response_json)
  end

  def expect_orca23_incomev3_02(path, body, mode, args, prev_response_json, response_json)
    expect(path).to eq(OrcaApi::IncomeService::PATH)

    req = body[OrcaApi::IncomeService::REQUEST_NAME]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq("02")
    expect(req["Request_Mode"]).to eq(mode)
    expect(req["Karte_Uid"]).to eq(orca_api.karte_uid)
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_ID"])

    if (income_detail = res_body["Income_Detail"])
      expect(req["InOut"]).to eq(income_detail["InOut"])
      expect(req["Invoice_Number"]).to eq(income_detail["Invoice_Number"])
    end

    attr_names = case mode
                 when "01"
                   %w(
                     Processing_Date
                     Processing_Time
                     Ic_Money
                     Ic_Code
                     Force_Flg
                   )
                 when "02"
                   %w(
                     History_Number
                     Processing_Date
                     Processing_Time
                     Ad_Money1
                     Ad_Money2
                     Ic_Money
                     Ic_Code
                   )
                 when "03"
                   %w(
                     Processing_Date
                     Processing_Time
                     Ic_Money
                     Ic_Code
                   )
                 when "04"
                   %w(
                     Processing_Date
                     Processing_Time
                   )
                 when "05"
                   %w(
                     Processing_Date
                     Processing_Time
                   )
                 when "06"
                   %w(
                   )
                 when "07"
                   %w(
                   )
                 when "08"
                   %w(
                   )
                 when "09"
                   %w(
                   )
                 else
                   raise "invalid mode: #{mode}"
                 end
    attr_names.each do |attr_name|
      expect(req[attr_name]).to eq(args[attr_name])
    end

    return_response_json(response_json)
  end

  def expect_orca23_incomev3_99(path, body, prev_response_json)
    expect(path).to eq(OrcaApi::IncomeService::PATH)

    req = body[OrcaApi::IncomeService::REQUEST_NAME]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(orca_api.karte_uid)
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response("orca23_incomev3_99.json")
  end

  describe "参照処理" do
    shared_context "ロックを伴う" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca23_incomev3_01(path, body, request_mode, args, response_json)
            when 2
              expect_orca23_incomev3_99(path, body, prev_response_json)
            end
          prev_response_json
        }
      end
    end

    shared_context "ロックを伴わない" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca23_incomev3_01(path, body, request_mode, args, response_json)
            end
          prev_response_json
        }
      end
    end

    describe "#list" do
      let(:request_mode) { "01" }

      let(:patient_id) { "1" }
      let(:start_date) { "" }
      let(:start_month) { "" }
      let(:args) {
        {
          "Patient_ID" => patient_id,
          "Information_Class" => information_class,
          "Start_Date" => start_date,
          "End_Date" => "",
          "Start_Month" => start_month,
          "End_Month" => "",
          "Sort_Key" => {
            "Key_Class" => "",
            "Order_Class" => "",
          }
        }
      }

      subject { service.list(args) }

      context "正常系" do
        include_context "ロックを伴う"

        shared_examples "結果が正しいこと" do
          its("ok?") { is_expected.to be true }

          %w(
            Income_Information
            Unpaid_Money_Total_Information
          ).each do |json_name|
            its([json_name]) { is_expected.to eq(response_data.first[1][json_name]) }
          end
        end

        context "Information_Class = 1:指定した期間内の請求一覧" do
          let(:information_class) { "1" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response("orca23_incomev3_01_01_information_class_1.json") }

          include_examples "結果が正しいこと"
        end

        context "Information_Class = 2:指定した期間内の未収（過入）金のある請求一覧" do
          let(:information_class) { "2" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response("orca23_incomev3_01_01_information_class_2.json") }

          include_examples "結果が正しいこと"
        end

        context "Information_Class = 3:指定した期間内に入返金が行われた請求一覧" do
          let(:information_class) { "2" }
          let(:start_date) { "2012-01-01" }
          let(:response_json) { load_orca_api_response("orca23_incomev3_01_01_information_class_3.json") }

          include_examples "結果が正しいこと"
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:information_class) { "1" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response("orca23_incomev3_01_01_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う"

          let(:information_class) { "1" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response("orca23_incomev3_01_01_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end

    describe "#get" do
      let(:request_mode) { "02" }

      let(:patient_id) { "1" }
      let(:invoice_number) { "13" }
      let(:args) {
        {
          "Patient_ID" => patient_id,
          "InOut" => "I",
          "Invoice_Number" => invoice_number,
        }
      }

      subject { service.get(args) }

      context "正常系" do
        include_context "ロックを伴う"

        let(:response_json) { load_orca_api_response("orca23_incomev3_01_02_get.json") }

        its("ok?") { is_expected.to be true }

        %w(
          Income_Detail
        ).each do |json_name|
          its([json_name]) { is_expected.to eq(response_data.first[1][json_name]) }
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:response_json) { load_orca_api_response("orca23_incomev3_01_02_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う"

          let(:response_json) { load_orca_api_response("orca23_incomev3_01_02_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end
  end

  describe "更新処理" do
    shared_examples "更新処理が期待通りに動作すること" do |json_names|
      subject { service.send(method_name, args) }

      context "正常系" do
        include_context "正常な日レセAPI呼び出し"

        let(:lock_response_json) { load_orca_api_response("orca23_incomev3_01_#{lock_request_mode}_#{method_name}.json") }
        let(:response_json) { load_orca_api_response("orca23_incomev3_02_#{request_mode}.json") }

        its("ok?") { is_expected.to be true }

        json_names.each do |json_name|
          its([json_name]) { is_expected.to eq(response_data.first[1][json_name]) }
        end
      end

      include_examples "他端末使用中に期待通りに動作すること"
    end

    shared_context "正常な日レセAPI呼び出し" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).exactly(3) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca23_incomev3_01(path, body, lock_request_mode, make_lock_args(args), lock_response_json)
            when 2
              expect_orca23_incomev3_02(path, body, request_mode, args, prev_response_json, response_json)
            when 3
              expect_orca23_incomev3_99(path, body, prev_response_json)
            end
          prev_response_json
        }
      end
    end

    shared_examples "他端末使用中に期待通りに動作すること" do
      context "他の端末より同じカルテＵＩＤでの接続があります。" do
        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca23_incomev3_01(path, body, lock_request_mode, make_lock_args(args), lock_response_json)
              end
            prev_response_json
          }
        end

        let(:lock_response_json) { load_orca_api_response("orca23_incomev3_01_#{lock_request_mode}_E1038.json") }

        its("ok?") { is_expected.to be false }
      end

      context "他端末使用中" do
        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).exactly(2) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca23_incomev3_01(path, body, lock_request_mode, make_lock_args(args), lock_response_json)
              when 2
                expect_orca23_incomev3_99(path, body, prev_response_json)
              end
            prev_response_json
          }
        end

        let(:lock_response_json) { load_orca_api_response("orca23_incomev3_01_#{lock_request_mode}_E9999.json") }

        its("ok?") { is_expected.to be false }
      end

      def make_lock_args(args)
        if args.key?("InOut") && args.key?("Invoice_Number")
          args
        else
          args.merge(
            "Information_Class" => "1",
            "Start_Month" => "0000-01",
            "Selection" => {
              "First" => "1",
              "Last" => "1",
            }
          )
        end
      end
    end

    describe "#update" do
      let(:method_name) { "update" }
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "01" }

      let(:ic_money) { "1000" }
      let(:force) { "False" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "InOut" => "I",
          "Invoice_Number" => "13",
          "Processing_Date" => "",
          "Processing_Time" => "",
          "Ic_Money" => ic_money,
          "Ic_Code" => "",
          "Force_Flg" => force,
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Ac_Money
        Ic_Money
        Unpaid_Money
        State
        State_Name
        Income_History
      )
      include_examples "更新処理が期待通りに動作すること", json_names do
        let(:ic_money) { "1000" }
      end

      context "過入金" do
        include_context "正常な日レセAPI呼び出し"

        context "強制入金" do
          let(:ic_money) { "10000" }
          let(:force) { "True" }

          let(:lock_response_json) { load_orca_api_response("orca23_incomev3_01_02_update.json") }
          let(:response_json) { load_orca_api_response("orca23_incomev3_02_01_force.json") }

          its("ok?") { is_expected.to be true }

          json_names.each do |json_name|
            its([json_name]) { is_expected.to eq(response_data.first[1][json_name]) }
          end
        end

        context "強制入金ではない" do
          let(:ic_money) { "10000" }
          let(:force) { "False" }

          let(:lock_response_json) { load_orca_api_response("orca23_incomev3_01_02_update.json") }
          let(:response_json) { load_orca_api_response("orca23_incomev3_02_01_E0107.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end

    describe "#update_history" do
      let(:method_name) { "update_history" }
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "02" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "InOut" => "I",
          "Invoice_Number" => "13",
          "History_Number" => "18",
          "Processing_Date" => "",
          "Processing_Time" => "",
          "Ad_Money1" => "",
          "Ad_Money2" => "",
          "Ic_Money" => "2000",
          "Ic_Code" => "",
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Ac_Money
        Ic_Money
        Unpaid_Money
        State
        State_Name
        Income_History
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#cancel" do
      let(:method_name) { "cancel" }
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "03" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "InOut" => "I",
          "Invoice_Number" => "13",
          "Processing_Date" => "",
          "Processing_Time" => "",
          "Ic_Money" => "-500",
          "Ic_Code" => "",
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Ac_Money
        Ic_Money
        Unpaid_Money
        State
        State_Name
        Income_History
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#pay_back" do
      let(:method_name) { "pay_back" }
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "04" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "InOut" => "I",
          "Invoice_Number" => "13",
          "Processing_Date" => "",
          "Processing_Time" => "",
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Ac_Money
        Ic_Money
        Unpaid_Money
        State
        State_Name
        Income_History
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#recalculate" do
      let(:method_name) { "recalculate" }
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "05" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "InOut" => "I",
          "Invoice_Number" => "13",
          "Processing_Date" => "",
          "Processing_Time" => "",
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Ac_Money
        Ic_Money
        Unpaid_Money
        State
        State_Name
        Income_History
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#bulk_recalculate" do
      let(:method_name) { "bulk_recalculate" }
      let(:lock_request_mode) { "01" }
      let(:request_mode) { "06" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "Perform_Month" => "2014-06",
          "Processing_Date" => "",
          "Processing_Time" => "",
        }
      }

      json_names = %w(
        Patient_ID
        Income_Information
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#bulk_update" do
      let(:method_name) { "bulk_update" }
      let(:lock_request_mode) { "01" }
      let(:request_mode) { "07" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "Income_Information" => [
            {
              "InOut" => "O",
              "Invoice_Number" => "749",
              "Processing_Date" => "",
              "Processing_Time" => "",
              "Ic_Class" => "1",
              "Ic_Money" => "1060",
              "Ic_Code" => "",
              "Force_Ic" => "",
            },
            {
              "InOut" => "O",
              "Invoice_Number" => "750",
              "Processing_Date" => "",
              "Processing_Time" => "",
              "Ic_Class" => "2",
              "Ic_Money" => "960",
              "Ic_Code" => "",
              "Force_Ic" => "",
            },
          ]
        }
      }

      json_names = %w(
        Patient_ID
        Income_Information
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#destroy" do
      let(:method_name) { "destroy" }
      let(:lock_request_mode) { "01" }
      let(:request_mode) { "08" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "Invoice_Number" => "13",
          "Processing_Date" => "",
          "Processing_Time" => "",
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Ac_Money
        Ic_Money
        Unpaid_Money
        State
        State_Name
        Income_History
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end

    describe "#reprint" do
      let(:method_name) { "reprint" }
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "09" }

      let(:args) {
        {
          "Patient_ID" => "1",
          "InOut" => "O",
          "Invoice_Number" => "13",
          "Print_Information" =>  {
            "Print_Invoice_Receipt_Class" => "1",
            "Print_Statement_Class" => "1"
          }
        }
      }

      json_names = %w(
        Patient_ID
        InOut
        Invoice_Number
        Print_Information
      )
      include_examples "更新処理が期待通りに動作すること", json_names
    end
  end
end
