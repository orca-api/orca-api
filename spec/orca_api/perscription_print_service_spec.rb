require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PrescriptionPrintService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#get_medical_fee" do
    before do
      expect(orca_api).to receive(:call_01).exactly(1) do |path|
        expect(path).to eq("/api21/medicalmodv31")
        response_json
      end
    end

    subject { service.get_medical_fee(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca21_medicalmodv31_01.json") }
      let(:args) do
        {
          "Karte_Uid" => "000000000000",
          "Patient_ID" => "000000000000",
          "Perform_Date" => "2019-01-01",
          "Perform_Time" => "10:00",
          "Patient_Mode" => "1",
          "Diagnosis_Information" => "診療情報",
        }
      end

      its("ok?") { is_expected.to be(true) }
    end
  end

  describe "#medical_treatment" do
    before do
      expect(orca_api).to receive(:medical_call).exactly(1) do |path|
        expect(path).to eq("/api21/medicalmodv32")
        response_json
      end
    end

    subject { service.medical_treatment(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca21_medicalmodv32_02.json") }
      let(:args) do
        {
          "Karte_Uid" => "000000000000",
          "Patient_ID" => "000000000000",
          "Perform_Date" => "2019-01-01",
          "Perform_Time" => "10:00",
          "Patient_Mode" => "1",
          "Patient_Mode" => "Print",
          "Print_Mode" => "PDF",
          "Diagnosis_Information" => "診療情報",
        }
      end

      its("ok?") { is_expected.to be(true) }
    end
  end

  describe "#medical_check" do
    before do
      expect(orca_api).to receive(:medical_call).exactly(1) do |path|
        expect(path).to eq("/api21/medicalmodv32")
        response_json
      end
    end

    subject { service.medical_check(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca21_medicalmodv32_03.json") }
      let(:args) do
        {
          "Karte_Uid" => "000000000000",
          "Patient_ID" => "000000000000",
          "Perform_Date" => "2019-01-01",
          "Perform_Time" => "10:00",
          "Patient_Mode" => "1",
          "Patient_Mode" => "Print",
          "Print_Mode" => "PDF",
        }
      end

      its("ok?") { is_expected.to be(true) }
    end
  end
end