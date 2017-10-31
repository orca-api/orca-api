require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PrintService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#create" do
    let(:patient_id) { "00216" }
    let(:invoice_number) { "0000861" }
    let(:outside_class) { true }
    let(:push_notification) { false }

    subject { service.create(type, patient_id, invoice_number, outside_class, push_notification) }

    shared_examples "結果が正しいこと" do
      its("ok?") { is_expected.to be(true) }

      %w(
        Patient
        Forms
      ).each do |json_name|
        its([json_name]) { is_expected.to eq(response_json[json_name]) }
      end
    end

    shared_examples "帳票印刷リクエストを送れること" do
      let(:expect_request_number) { "02" }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              aggregate_failures "リクエスト内容のチェック" do
                expect(path).to eq(expect_path)

                req = body[expect_request_name]
                expect(req["Request_Number"]).to eq(expect_request_number)
                expect(req["Patient_ID"]).to eq(patient_id.to_s)
                expect(req["Invoice_Number"]).to eq(invoice_number.to_s)
                expect(req["Outside_Class"]).to eq(outside_class ? "True" : "False")
              end

              response_json
            end
          prev_response_json
        }
      end

      context "正常系" do
        let(:response_json) { load_orca_api_response_json("#{json_prefix}.json", false) }

        include_examples "結果が正しいこと"

        context "push通知を有効にする" do
          let(:push_notification) { true }
          let(:expect_request_number) { "01" }

          include_examples "結果が正しいこと"
        end
      end

      context "異常系" do
        context "存在しない伝票番号を指定する" do
          let(:invoice_number) { "0000862" }

          let(:response_json) { load_orca_api_response_json("#{json_prefix}_0105.json", false) }

          its("ok?") { is_expected.to be(false) }
        end
      end
    end

    describe "処方箋" do
      let(:type) { "shohosen" }

      let(:expect_path) { "/api01rv2/prescriptionv2" }
      let(:expect_request_name) { "prescriptionv2req" }

      let(:json_prefix) { "api01rv2_prescriptionv2" }

      include_examples "帳票印刷リクエストを送れること"
    end

    describe "お薬手帳" do
      let(:type) { "okusuri_techo" }

      let(:expect_path) { "/api01rv2/medicinenotebookv2" }
      let(:expect_request_name) { "medicine_notebookv2req" }

      let(:json_prefix) { "api01rv2_medicinenotebookv2" }

      include_examples "帳票印刷リクエストを送れること"
    end

    context "対応していない帳票種別を指定する" do
      let(:type) { "unknown" }

      it { expect { subject }.to raise_error(ArgumentError, "対応していない帳票種別です: #{type}") }
    end
  end
end
