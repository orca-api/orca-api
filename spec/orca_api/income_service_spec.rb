# -*- coding: utf-8 -*-

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::IncomeService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

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
    res_body = prev_response_json.first[1]
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
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(orca_api.karte_uid)
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response_json("orca23_incomev3_99.json")
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
            its([json_name]) { is_expected.to eq(response_json.first[1][json_name]) }
          end
        end

        context "Information_Class = 1:指定した期間内の請求一覧" do
          let(:information_class) { "1" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_01_information_class_1.json") }

          include_examples "結果が正しいこと"
        end

        context "Information_Class = 2:指定した期間内の未収（過入）金のある請求一覧" do
          let(:information_class) { "2" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_01_information_class_2.json") }

          include_examples "結果が正しいこと"
        end

        context "Information_Class = 3:指定した期間内に入返金が行われた請求一覧" do
          let(:information_class) { "2" }
          let(:start_date) { "2012-01-01" }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_01_information_class_3.json") }

          include_examples "結果が正しいこと"
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:information_class) { "1" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_01_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う"

          let(:information_class) { "1" }
          let(:start_month) { "2012-01" }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_01_E9999.json") }

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

        let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_02_get.json") }

        its("ok?") { is_expected.to be true }

        %w(
          Income_Detail
        ).each do |json_name|
          its([json_name]) { is_expected.to eq(response_json.first[1][json_name]) }
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う"

          let(:response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end
  end

  describe "更新処理" do
    shared_context "ロックを伴う" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).exactly(3) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca23_incomev3_01(path, body, lock_request_mode, args, lock_response_json)
            when 2
              expect_orca23_incomev3_02(path, body, request_mode, args, prev_response_json, response_json)
            when 3
              expect_orca23_incomev3_99(path, body, prev_response_json)
            end
          prev_response_json
        }
      end
    end

    shared_context "ロックを伴う/他端末使用中" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca23_incomev3_01(path, body, lock_request_mode, args, lock_response_json)
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
              expect_orca23_incomev3_01(path, body, lock_request_mode, args, lock_response_json)
            end
          prev_response_json
        }
      end
    end

    describe "#update" do
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "01" }

      let(:patient_id) { "1" }
      let(:invoice_number) { "13" }
      let(:ic_money) { "1000" }
      let(:force) { "False" }
      let(:args) {
        {
          "Patient_ID" => patient_id,
          "InOut" => "I",
          "Invoice_Number" => invoice_number,
          "Processing_Date" => "",
          "Processing_Time" => "",
          "Ic_Money" => ic_money,
          "Ic_Code" => "",
          "Force_Flg" => force,
        }
      }

      subject { service.update(args) }

      context "正常系" do
        include_context "ロックを伴う"

        shared_examples "結果が正しいこと" do
          its("ok?") { is_expected.to be true }

          %w(
            Patient_ID
            InOut
            Invoice_Number
            Ac_Money
            Ic_Money
            Unpaid_Money
            State
            State_Name
            Income_History
          ).each do |json_name|
            its([json_name]) { is_expected.to eq(response_json.first[1][json_name]) }
          end
        end

        context "過入金ではない" do
          let(:ic_money) { "1000" }

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_update.json") }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_02_01.json") }

          include_examples "結果が正しいこと"
        end

        context "過入金" do
          let(:ic_money) { "10000" }
          let(:force) { "True" }

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_update.json") }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_02_01_force.json") }

          include_examples "結果が正しいこと"
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "過入金" do
          include_context "ロックを伴う"

          let(:ic_money) { "10000" }
          let(:force) { "False" }

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_update.json") }
          let(:response_json) { load_orca_api_response_json("orca23_incomev3_02_01_E0107.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う/他端末使用中"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end

    describe "#update_history" do
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "02" }

      let(:patient_id) { "1" }
      let(:invoice_number) { "13" }
      let(:history_number) { "1" }
      let(:ic_money) { "1000" }
      let(:args) {
        {
          "Patient_ID" => patient_id,
          "InOut" => "I",
          "Invoice_Number" => invoice_number,
          "History_Number" => history_number,
          "Processing_Date" => "",
          "Processing_Time" => "",
          "Ad_Money1" => "",
          "Ad_Money2" => "",
          "Ic_Money" => ic_money,
          "Ic_Code" => "",
        }
      }

      subject { service.update_history(args) }

      context "正常系" do
        include_context "ロックを伴う"

        let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_update_history.json") }
        let(:response_json) { load_orca_api_response_json("orca23_incomev3_02_02.json") }

        its("ok?") { is_expected.to be true }

        %w(
          Patient_ID
          InOut
          Invoice_Number
          Ac_Money
          Ic_Money
          Unpaid_Money
          State
          State_Name
          Income_History
        ).each do |json_name|
          its([json_name]) { is_expected.to eq(response_json.first[1][json_name]) }
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う/他端末使用中"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end

    describe "#cancel" do
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "03" }

      let(:patient_id) { "1" }
      let(:invoice_number) { "13" }
      let(:ic_money) { "-500" }
      let(:args) {
        {
          "Patient_ID" => patient_id,
          "InOut" => "I",
          "Invoice_Number" => invoice_number,
          "Processing_Date" => "",
          "Processing_Time" => "",
          "Ic_Money" => ic_money,
          "Ic_Code" => "",
        }
      }

      subject { service.cancel(args) }

      context "正常系" do
        include_context "ロックを伴う"

        let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_cancel.json") }
        let(:response_json) { load_orca_api_response_json("orca23_incomev3_02_03.json") }

        its("ok?") { is_expected.to be true }

        %w(
          Patient_ID
          InOut
          Invoice_Number
          Ac_Money
          Ic_Money
          Unpaid_Money
          State
          State_Name
          Income_Detail_Information
        ).each do |json_name|
          its([json_name]) { is_expected.to eq(response_json.first[1][json_name]) }
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う/他端末使用中"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end

    describe "#pay_back" do
      let(:lock_request_mode) { "02" }
      let(:request_mode) { "04" }

      let(:patient_id) { "1" }
      let(:invoice_number) { "13" }
      let(:args) {
        {
          "Patient_ID" => patient_id,
          "InOut" => "I",
          "Invoice_Number" => invoice_number,
          "Processing_Date" => "",
          "Processing_Time" => "",
        }
      }

      subject { service.pay_back(args) }

      context "正常系" do
        include_context "ロックを伴う"

        let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_pay_back.json") }
        let(:response_json) { load_orca_api_response_json("orca23_incomev3_02_04.json") }

        its("ok?") { is_expected.to be true }

        %w(
          Patient_ID
          InOut
          Invoice_Number
        ).each do |json_name|
          its([json_name]) { is_expected.to eq(response_json.first[1][json_name]) }
        end
      end

      context "異常系" do
        context "他の端末より同じカルテＵＩＤでの接続があります。" do
          include_context "ロックを伴わない"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E1038.json") }

          its("ok?") { is_expected.to be false }
        end

        context "他端末使用中" do
          include_context "ロックを伴う/他端末使用中"

          let(:lock_response_json) { load_orca_api_response_json("orca23_incomev3_01_02_E9999.json") }

          its("ok?") { is_expected.to be false }
        end
      end
    end
  end
end
