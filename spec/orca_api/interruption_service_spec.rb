require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::InterruptionService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#list" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path|
        expect(path).to eq("/api01rv2/tmedicalgetv2")
        response_json
      end
    end

    subject { service.list(args) }

    context '正常系' do
      let(:response_json) { load_orca_api_response("api01rv2_tmedicalgetv2_list.json") }
      let(:args) do
        {
          Perform_Date: response_data["tmedicalgetres"]["Perform_Date"],
          InOut: response_data["tmedicalgetres"]["InOut"],
          Department_Code: "01"
        }
      end

      its("ok?") { is_expected.to be(true) }
    end

    context '異常系' do
      let(:response_json) { load_orca_api_response("api01rv2_tmedicalgetv2_list_15.json") }
      let(:args) { {} }

      its("ok?") { is_expected.to be(false) }
    end
  end

  describe "#detail" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path|
        expect(path).to eq("/api21/tmedicalmodv2")
        response_json
      end
    end

    subject { service.detail(args) }

    context '正常系' do
      let(:response_json) { load_orca_api_response("api21_tmedicalmodv2_detail.json") }
      let(:args) do
        {
          Perform_Date: response_data["tmedicalmodres"]["Perform_Date"],
          Department_Code: response_data["tmedicalmodres"]["Department_Code"],
          Patient_ID: response_data["tmedicalmodres"]["Patient_Information"]["Patient_ID"],
          Medical_Uid: response_data["tmedicalmodres"]["Medical_Uid"]
        }
      end

      its("ok?") { is_expected.to be(true) }
    end

    context '異常系' do
      let(:response_json) { load_orca_api_response("api21_tmedicalmodv2_detail_15.json") }
      let(:args) { {} }

      its("ok?") { is_expected.to be(false) }
    end
  end

  describe "#create" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path, params:, body:|
        expect(path).to eq("/api21/medicalmodv2")
        expect(params[:class]).to eq("01")
        response_json
      end
    end

    subject { service.create(args) }

    context '正常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_create.json") }
      let(:args) do
        {
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Diagnosis_Information: {
            Department_Code: response_data["medicalres"]["Department_Code"],
            Physician_Code: response_data["medicalres"]["Physician_Code"],
            HealthInsurance_Information: response_data["medicalres"]["Patient_Information"]["HealthInsurance_Information"],
            Medical_Information: [
              {
                Medical_Class: "110",
                Medical_Class_Name: "初診料",
                Medication_info: [
                  {
                    Medication_Code: "111000110",
                    Medication_Name: "初診料",
                    Medication_Number: "1"
                  }
                ]
              },
              {
                Medical_Class: "212",
                Medical_Class_Name: "内服",
                Medication_info: [
                  {
                    Medication_Code: "621978201",
                    Medication_Name: "サインバルタカプセル２０ｍｇ",
                    Medication_Number: "1"
                  },
                  {
                    Medication_Code: "099209908",
                    Medication_Name: "一般名記載",
                    Medication_Number: "1"
                  }
                ]
              },
              {
                Medical_Class: "820",
                Medical_Class_Name: "処方箋料",
                Medication_info: [
                  {
                    Medication_Code: "120003570",
                    Medication_Name: "一般名処方加算２（処方箋料）",
                    Medication_Number: "1"
                  }
                ]
              }
            ]
          }
        }
      end

      its("ok?") { is_expected.to be(true) }
    end

    context '異常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_create_22.json") }
      let(:args) do
        {
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Diagnosis_Information: {
            Department_Code: response_data["medicalres"]["Department_Code"],
            Physician_Code: response_data["medicalres"]["Physician_Code"],
            HealthInsurance_Information: response_data["medicalres"]["Patient_Information"]["HealthInsurance_Information"],
            Medical_Information: []
          }
        }
      end

      its("ok?") { is_expected.to be(false) }
      its("api_result") { is_expected.to eq("22") }
    end
  end

  describe "#destroy" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path, params:, body:|
        expect(path).to eq("/api21/medicalmodv2")
        expect(params[:class]).to eq("02")
        response_json
      end
    end

    subject { service.destroy(args) }

    context '正常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_destroy.json") }
      let(:args) do
        {
          Perform_Date: response_data["medicalres"]["Perform_Date"],
          Department_Code: response_data["medicalres"]["Department_Code"],
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Medical_Uid: response_data["medicalres"]["Medical_Uid"]
        }
      end

      its("ok?") { is_expected.to be(true) }
    end

    context '異常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_destroy_30.json") }
      let(:args) { {} }

      its("ok?") { is_expected.to be(false) }
      its("api_result") { is_expected.to eq("30") }
    end
  end

  describe "#update" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path, params:, body:|
        expect(path).to eq("/api21/medicalmodv2")
        expect(params[:class]).to eq("03")
        response_json
      end
    end

    subject { service.update(args) }

    context '正常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_update.json") }
      let(:args) do
        {
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Diagnosis_Information: {
            Department_Code: response_data["medicalres"]["Department_Code"],
            Physician_Code: response_data["medicalres"]["Physician_Code"],
            HealthInsurance_Information: response_data["medicalres"]["Patient_Information"]["HealthInsurance_Information"],
            Medical_Information: [
              {
                Medical_Class: "110",
                Medical_Class_Name: "初診料",
                Medication_info: [
                  {
                    Medication_Code: "111000110",
                    Medication_Name: "初診料",
                    Medication_Number: "1"
                  }
                ]
              }
            ]
          }
        }
      end

      its("ok?") { is_expected.to be(true) }
    end

    context '異常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_update_22.json") }
      let(:args) do
        {
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Diagnosis_Information: {
            Department_Code: response_data["medicalres"]["Department_Code"],
            Physician_Code: response_data["medicalres"]["Physician_Code"]
          }
        }
      end

      its("ok?") { is_expected.to be(false) }
      its("api_result") { is_expected.to eq("22") }
    end
  end

  describe "#out_create" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path, params:, body:|
        expect(path).to eq("/api21/medicalmodv2")
        expect(params[:class]).to eq("04")
        response_json
      end
    end

    subject { service.out_create(args) }

    context '正常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_out_create.json") }
      let(:args) do
        {
          Perform_Date: response_data["medicalres"]["Perform_Date"],
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Diagnosis_Information: {
            Department_Code: response_data["medicalres"]["Department_Code"],
            Physician_Code: response_data["medicalres"]["Physician_Code"],
            HealthInsurance_Information: response_data["medicalres"]["Patient_Information"]["HealthInsurance_Information"],
            Medical_Information: [
              {
                Medical_Class: "600",
                Medication_info: [
                  {
                    Medication_Code: "160118810",
                    Medication_Number: "1"
                  }
                ]
              }
            ]
          }
        }
      end

      its("ok?") { is_expected.to be(true) }
    end

    context '異常系' do
      let(:response_json) { load_orca_api_response("api21_medicalmodv2_out_create_22.json") }
      let(:args) do
        {
          Perform_Date: response_data["medicalres"]["Perform_Date"],
          Patient_ID: response_data["medicalres"]["Patient_Information"]["Patient_ID"],
          Diagnosis_Information: {
            Department_Code: response_data["medicalres"]["Department_Code"],
            Physician_Code: response_data["medicalres"]["Physician_Code"],
            HealthInsurance_Information: response_data["medicalres"]["Patient_Information"]["HealthInsurance_Information"],
            Medical_Information: []
          }
        }
      end

      its("ok?") { is_expected.to be(false) }
      its("api_result") { is_expected.to eq("22") }
    end
  end
end
