# coding: utf-8

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PatientService, "::CreateMedicalPractice", patient_service_with_orca_api_mock: true do
  describe "#get_examination_fee" do
    let(:patient_id) { 4 }
    let(:diagnosis) {
      {
        "Perform_Date" => "2017-07-31",
        "Perform_Time" => "10:30:00",
        "Diagnosis_Information" => {
          "Department_Code" => "01",
          "Physician_Code" => "10001",
          "HealthInsurance_Information" => {
            "Insurance_Combination_Number" => "0009",
          },
          "Medical_Information" => {
            "OffTime" => "0",
            "Doctors_Fee" => "02",
            "Medical_Class" => "",
            "Medical_Class_Name" => "",
            "Medication_Info" => {
              "Medication_Code" => "",
              "Medication_Name" => "",
            },
          },
        },
      }
    }
    let(:args) {
      [patient_id, diagnosis]
    }
    let(:response_json) { load_orca_api_response_json("api21_medicalmodv31_01.json") }

    subject { patient_service.get_examination_fee(*args) }

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
        count += 1
        case count
        when 1
          expect(path).to eq("/api21/medicalmodv31")

          req = body["medicalv3req1"]
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Patient_ID"]).to eq(patient_id.to_s)
          expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
          expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Diagnosis_Information"]).to eq(diagnosis["Diagnosis_Information"])

          prev_response_json = response_json
          prev_response_json
        when 2
          expect(path).to eq("/api21/medicalmodv31")

          req = body["medicalv3req1"]
          res_body = prev_response_json.first[1]
          expect(req["Request_Number"]).to eq("99")
          expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
          expect(req["Patient_ID"]).to eq(patient_id.to_s)
          expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
          expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

          load_orca_api_response_json("api21_medicalmodv31_99.json")
        end
      }
    end

    its("ok?") { is_expected.to be true }
    its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }

    context "Perform_Dateが未指定であるためレスポンスがW00" do
      let(:diagnosis) {
        super().tap { |d| d.delete("Perform_Date") }
      }
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv31_01_W00.json") }

      its("ok?") { is_expected.to be true }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
    end
  end

  describe "#create_medical_practice" do
    let(:args) {
      [patient_id, diagnosis]
    }

    subject { patient_service.create_medical_practice(*args) }

    context "正常終了" do
      let(:patient_id) { 4 }
      let(:diagnosis) {
        {
          "Perform_Date" => "2017-07-31",
          "Perform_Time" => "10:30:00",
          "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
          "Diagnosis_Information" => {
            "Department_Code" => "01",
            "Physician_Code" => "10001",
            "HealthInsurance_Information" => {
              "Insurance_Combination_Number" => "0009",
            },
            "Outside_Class" => "False", #	院内 False, 院外 True
            "Medical_Information" => {
              "OffTime" => "0",
              "Doctors_Fee" => "02",
              "Medical_Info" => [
                {
                  "Medical_Class" => "120",
                  "Medical_Class_Name" => "再診料",
                  "Medical_Class_Number" => "1",
                  "Medication_Info" => [
                    {
                      "Medication_Code" => "101120010",
                      "Medication_Name" => "再診料",
                    },
                    {
                      "Medication_Code" => "112016070",
                      "Medication_Name" => "時間外対応加算１",
                    },
                    {
                      "Medication_Code" => "112015770",
                      "Medication_Name" => "明細書発行体制等加算",
                    }
                  ]
                },
                {
                  "Medical_Class" => "120",
                  "Medical_Class_Name" => "再診料",
                  "Medical_Class_Number" => "1",
                  "Medication_Info" => [
                    {
                      "Medication_Code" => "112011010",
                      "Medication_Name" => "外来管理加算",
                      "Medication_Number" => "1",
                    }
                  ]
                },
              ],
            },
          },
          "Ic_Code" => "", # 未設定は、システム管理・患者登録設定内容
          "Ic_Money" => "", # 未設定時は、Ic_Codeに従う
          "Ad_Money1" => "", # 未設定時は、0円
          "Ad_Money2" => "", # 未設定時は、0円
        }
      }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
          count += 1
          case count
          when 1
            expect(path).to eq("/api21/medicalmodv31")

            req = body["medicalv3req1"]
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
            expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
            expect(req["Orca_Uid"]).to eq("")
            req_diagnosis = req["Diagnosis_Information"]
            arg_diagnosis = diagnosis["Diagnosis_Information"]
            expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
            expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
            expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
              to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
            expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
            expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

            prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
            prev_response_json
          when 2
            expect(path).to eq("/api21/medicalmodv32")

            req = body["medicalv3req2"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Invoice_Number"]).to be_nil
            req_diagnosis = req["Diagnosis_Information"]
            expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
            expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
            expect(req_diagnosis["HealthInsurance_Information"]).
              to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
            expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
            expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
              to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

            prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
            prev_response_json
          when 3
            expect(path).to eq("/api21/medicalmodv32")

            req = body["medicalv3req2"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Invoice_Number"]).to be_nil
            expect(req["Select_Mode"]).to be_nil
            expect(req["Select_Answer"]).to be_nil

            prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03.json")
            prev_response_json
          when 4
            expect(path).to eq("/api21/medicalmodv33")

            req = body["medicalv3req3"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Base_Date"]).to eq(diagnosis["Base_Date"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to be_nil
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Medical_Mode"]).to be_nil
            expect(req["Delete_Number_Info"]).to be_nil
            expect(req["Ic_Code"]).to eq(diagnosis["Ic_Code"])
            expect(req["Ic_Money"]).to eq(diagnosis["Ic_Money"])
            expect(req["Ad_Money1"]).to eq(diagnosis["Ad_Money1"])
            expect(req["Ad_Money2"]).to eq(diagnosis["Ad_Money2"])
            expect(req["Re_Money"]).to be_nil

            prev_response_json = load_orca_api_response_json("api21_medicalmodv33_04.json")
            prev_response_json
          when 5
            expect(path).to eq("/api21/medicalmodv33")

            req = body["medicalv3req3"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Base_Date"]).to eq(diagnosis["Base_Date"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to be_nil
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Ic_Code"]).to eq(diagnosis["Ic_Code"])
            expect(req["Ic_Money"]).to eq(diagnosis["Ic_Money"])
            expect(req["Ad_Money1"]).to eq(diagnosis["Ad_Money1"])
            expect(req["Ad_Money2"]).to eq(diagnosis["Ad_Money2"])
            expect(req["Re_Money"]).to be_nil

            prev_response_json = load_orca_api_response_json("api21_medicalmodv33_05.json")
            prev_response_json
          end
        }
      end

      its("ok?") { is_expected.to be true }
      it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::Result) }
    end

    describe "診療行為を指定しなければ、デフォルトの診療行為情報(Medical_Information)を取得できる" do
      let(:patient_id) { 4 }
      let(:diagnosis) {
        {
          "Perform_Date" => "2017-07-31",
          "Perform_Time" => "10:30:00",
          "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
          "Diagnosis_Information" => {
            "Department_Code" => "01",
            "Physician_Code" => "10001",
            "HealthInsurance_Information" => {
              "Insurance_Combination_Number" => "0009",
            },
            "Outside_Class" => "False", #	院内 False, 院外 True
            "Medical_Information" => {
              "OffTime" => "0",
              "Doctors_Fee" => "02",
            },
          },
        }
      }
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv31_01.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          case count
          when 1
            expect(path).to eq("/api21/medicalmodv31")

            req = body["medicalv3req1"]
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
            expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
            expect(req["Orca_Uid"]).to eq("")
            req_diagnosis = req["Diagnosis_Information"]
            arg_diagnosis = diagnosis["Diagnosis_Information"]
            expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
            expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
            expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
              to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
            expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
            expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

            prev_response_json = response_json
            prev_response_json
          when 2
            expect(path).to eq("/api21/medicalmodv31")

            req = body["medicalv3req1"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq("99")
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

            prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
            prev_response_json
          end
        }
      end

      its("ok?") { is_expected.to be false }
      it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::EmptyMedicalInfoError) }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
    end

    describe "入金情報を指定しなければ、収納情報を取得できる" do
      let(:patient_id) { 4 }
      let(:diagnosis) {
        {
          "Perform_Date" => "2017-07-31",
          "Perform_Time" => "10:30:00",
          "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
          "Diagnosis_Information" => {
            "Department_Code" => "01",
            "Physician_Code" => "10001",
            "HealthInsurance_Information" => {
              "Insurance_Combination_Number" => "0009",
            },
            "Outside_Class" => "False", #	院内 False, 院外 True
            "Medical_Information" => {
              "OffTime" => "0",
              "Doctors_Fee" => "02",
              "Medical_Info" => [
                {
                  "Medical_Class" => "120",
                  "Medical_Class_Name" => "再診料",
                  "Medical_Class_Number" => "1",
                  "Medication_Info" => [
                    {
                      "Medication_Code" => "101120010",
                      "Medication_Name" => "再診料",
                    },
                    {
                      "Medication_Code" => "112016070",
                      "Medication_Name" => "時間外対応加算１",
                    },
                    {
                      "Medication_Code" => "112015770",
                      "Medication_Name" => "明細書発行体制等加算",
                    }
                  ]
                },
                {
                  "Medical_Class" => "120",
                  "Medical_Class_Name" => "再診料",
                  "Medical_Class_Number" => "1",
                  "Medication_Info" => [
                    {
                      "Medication_Code" => "112011010",
                      "Medication_Name" => "外来管理加算",
                      "Medication_Number" => "1",
                    }
                  ]
                },
              ],
            },
          },
        }
      }
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
          count += 1
          case count
          when 1
            expect(path).to eq("/api21/medicalmodv31")

            req = body["medicalv3req1"]
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
            expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
            expect(req["Orca_Uid"]).to eq("")
            req_diagnosis = req["Diagnosis_Information"]
            arg_diagnosis = diagnosis["Diagnosis_Information"]
            expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
            expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
            expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
              to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
            expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
            expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

            prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
            prev_response_json
          when 2
            expect(path).to eq("/api21/medicalmodv32")

            req = body["medicalv3req2"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Invoice_Number"]).to be_nil
            req_diagnosis = req["Diagnosis_Information"]
            expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
            expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
            expect(req_diagnosis["HealthInsurance_Information"]).
              to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
            expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
            expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
              to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

            prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
            prev_response_json
          when 3
            expect(path).to eq("/api21/medicalmodv32")

            req = body["medicalv3req2"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Invoice_Number"]).to be_nil
            expect(req["Select_Mode"]).to be_nil
            expect(req["Select_Answer"]).to be_nil

            prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03.json")
            prev_response_json
          when 4
            expect(path).to eq("/api21/medicalmodv33")

            req = body["medicalv3req3"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq(res_body["Response_Number"])
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Base_Date"]).to eq(diagnosis["Base_Date"])
            expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Perform_Time"]).to be_nil
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
            expect(req["Patient_Mode"]).to be_nil
            expect(req["Medical_Mode"]).to be_nil
            expect(req["Delete_Number_Info"]).to be_nil
            expect(req["Ic_Code"]).to be_nil
            expect(req["Ic_Money"]).to be_nil
            expect(req["Ad_Money1"]).to be_nil
            expect(req["Ad_Money2"]).to be_nil
            expect(req["Re_Money"]).to be_nil

            prev_response_json = response_json
            prev_response_json
          when 5
            expect(path).to eq("/api21/medicalmodv31")

            req = body["medicalv3req1"]
            res_body = prev_response_json.first[1]
            expect(req["Request_Number"]).to eq("99")
            expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
            expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

            prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
            prev_response_json
          end
        }
      end

      its("ok?") { is_expected.to be false }
      it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::EmptyIcError) }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
    end

    context "選択項目がある" do
      context "選択項目を指定していない" do
        let(:patient_id) { 4 }
        let(:diagnosis) {
          {
            "Perform_Date" => "2017-07-31",
            "Perform_Time" => "10:30:00",
            "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
            "Diagnosis_Information" => {
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0009",
              },
              "Outside_Class" => "False", #	院内 False, 院外 True
              "Medical_Information" => {
                "OffTime" => "0",
                "Doctors_Fee" => "02",
                "Medical_Info" => [
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "101120010",
                        "Medication_Name" => "再診料",
                      },
                      {
                        "Medication_Code" => "112016070",
                        "Medication_Name" => "時間外対応加算１",
                      },
                      {
                        "Medication_Code" => "112015770",
                        "Medication_Name" => "明細書発行体制等加算",
                      }
                    ]
                  },
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "112011010",
                        "Medication_Name" => "外来管理加算",
                        "Medication_Number" => "1",
                      }
                    ]
                  },
                ],
              },
            },
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_select.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            case count
            when 1
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq("karte_uid")
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
              expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
              expect(req["Orca_Uid"]).to eq("")
              req_diagnosis = req["Diagnosis_Information"]
              arg_diagnosis = diagnosis["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
                to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
              expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
              expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).
                to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
              prev_response_json
            when 2
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              req_diagnosis = req["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]).
                to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
              expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
              expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
                to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
              prev_response_json
            when 3
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to be_nil

              prev_response_json = response_json
              prev_response_json
            when 4
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq("99")
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
              prev_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::UnselectedError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:medical_select_information) { is_expected.to eq(response_json.first[1]["Medical_Select_Information"]) }
      end

      context "選択項目を指定する" do
        let(:patient_id) { 4 }
        let(:diagnosis) {
          {
            "Perform_Date" => "2017-07-31",
            "Perform_Time" => "10:30:00",
            "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
            "Diagnosis_Information" => {
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0009",
              },
              "Outside_Class" => "False", #	院内 False, 院外 True
              "Medical_Information" => {
                "OffTime" => "0",
                "Doctors_Fee" => "02",
                "Medical_Info" => [
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "101120010",
                        "Medication_Name" => "再診料",
                      },
                      {
                        "Medication_Code" => "112016070",
                        "Medication_Name" => "時間外対応加算１",
                      },
                      {
                        "Medication_Code" => "112015770",
                        "Medication_Name" => "明細書発行体制等加算",
                      }
                    ]
                  },
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "112011010",
                        "Medication_Name" => "外来管理加算",
                        "Medication_Number" => "1",
                      }
                    ]
                  },
                ],
              },
            },
            "Medical_Select_Information" => [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
            ],
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(6) { |path, body:|
            count += 1
            case count
            when 1
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq("karte_uid")
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
              expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
              expect(req["Orca_Uid"]).to eq("")
              req_diagnosis = req["Diagnosis_Information"]
              arg_diagnosis = diagnosis["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
                to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
              expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
              expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).
                to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
              prev_response_json
            when 2
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              req_diagnosis = req["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]).
                to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
              expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
              expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
                to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
              prev_response_json
            when 3
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to be_nil

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03_select.json")
              prev_response_json
            when 4
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to eq(diagnosis["Medical_Select_Information"][0]["Select_Answer"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03.json")
              prev_response_json
            when 5
              expect(path).to eq("/api21/medicalmodv33")

              req = body["medicalv3req3"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Base_Date"]).to eq(diagnosis["Base_Date"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to be_nil
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Medical_Mode"]).to be_nil
              expect(req["Delete_Number_Info"]).to be_nil
              expect(req["Ic_Code"]).to eq(diagnosis["Ic_Code"])
              expect(req["Ic_Money"]).to eq(diagnosis["Ic_Money"])
              expect(req["Ad_Money1"]).to eq(diagnosis["Ad_Money1"])
              expect(req["Ad_Money2"]).to eq(diagnosis["Ad_Money2"])
              expect(req["Re_Money"]).to be_nil

              prev_response_json = response_json
              prev_response_json
            when 6
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq("99")
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
              prev_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::EmptyIcError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end

      context "選択項目が2つあるが、1つしか指定していない" do
        let(:patient_id) { 4 }
        let(:diagnosis) {
          {
            "Perform_Date" => "2017-07-31",
            "Perform_Time" => "10:30:00",
            "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
            "Diagnosis_Information" => {
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0009",
              },
              "Outside_Class" => "False", #	院内 False, 院外 True
              "Medical_Information" => {
                "OffTime" => "0",
                "Doctors_Fee" => "02",
                "Medical_Info" => [
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "101120010",
                        "Medication_Name" => "再診料",
                      },
                      {
                        "Medication_Code" => "112016070",
                        "Medication_Name" => "時間外対応加算１",
                      },
                      {
                        "Medication_Code" => "112015770",
                        "Medication_Name" => "明細書発行体制等加算",
                      }
                    ]
                  },
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "112011010",
                        "Medication_Name" => "外来管理加算",
                        "Medication_Number" => "1",
                      }
                    ]
                  },
                ],
              },
            },
            "Medical_Select_Information" => [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
            ],
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_select2.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
            count += 1
            case count
            when 1
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq("karte_uid")
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
              expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
              expect(req["Orca_Uid"]).to eq("")
              req_diagnosis = req["Diagnosis_Information"]
              arg_diagnosis = diagnosis["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
                to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
              expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
              expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).
                to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
              prev_response_json
            when 2
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              req_diagnosis = req["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]).
                to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
              expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
              expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
                to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
              prev_response_json
            when 3
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to be_nil

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03_select.json")
              prev_response_json
            when 4
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to eq(diagnosis["Medical_Select_Information"][0]["Select_Answer"])

              prev_response_json = response_json
              prev_response_json
            when 5
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq("99")
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
              prev_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::UnselectedError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:medical_select_information) { is_expected.to eq(response_json.first[1]["Medical_Select_Information"]) }
      end

      context "2つの選択項目を指定する" do
        let(:patient_id) { 4 }
        let(:diagnosis) {
          {
            "Perform_Date" => "2017-07-31",
            "Perform_Time" => "10:30:00",
            "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
            "Diagnosis_Information" => {
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0009",
              },
              "Outside_Class" => "False", #	院内 False, 院外 True
              "Medical_Information" => {
                "OffTime" => "0",
                "Doctors_Fee" => "02",
                "Medical_Info" => [
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "101120010",
                        "Medication_Name" => "再診料",
                      },
                      {
                        "Medication_Code" => "112016070",
                        "Medication_Name" => "時間外対応加算１",
                      },
                      {
                        "Medication_Code" => "112015770",
                        "Medication_Name" => "明細書発行体制等加算",
                      }
                    ]
                  },
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "112011010",
                        "Medication_Name" => "外来管理加算",
                        "Medication_Number" => "1",
                      }
                    ]
                  },
                ],
              },
            },
            "Medical_Select_Information" => [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
              {
                "Medical_Select" => "2003",
                "Medical_Select_Message" => "手帳記載加算（薬剤情報提供料）を算定します。よろしいですか？",
                "Select_Answer" => "Ok",
              },
            ],
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(7) { |path, body:|
            count += 1
            case count
            when 1
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq("karte_uid")
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
              expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
              expect(req["Orca_Uid"]).to eq("")
              req_diagnosis = req["Diagnosis_Information"]
              arg_diagnosis = diagnosis["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
                to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
              expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
              expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).
                to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
              prev_response_json
            when 2
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              req_diagnosis = req["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]).
                to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
              expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
              expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
                to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
              prev_response_json
            when 3
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to be_nil

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03_select.json")
              prev_response_json
            when 4
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to eq(diagnosis["Medical_Select_Information"][0]["Select_Answer"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03_select2.json")
              prev_response_json
            when 5
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to eq(diagnosis["Medical_Select_Information"][1]["Select_Answer"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03.json")
              prev_response_json
            when 6
              expect(path).to eq("/api21/medicalmodv33")

              req = body["medicalv3req3"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Base_Date"]).to eq(diagnosis["Base_Date"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to be_nil
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Medical_Mode"]).to be_nil
              expect(req["Delete_Number_Info"]).to be_nil
              expect(req["Ic_Code"]).to eq(diagnosis["Ic_Code"])
              expect(req["Ic_Money"]).to eq(diagnosis["Ic_Money"])
              expect(req["Ad_Money1"]).to eq(diagnosis["Ad_Money1"])
              expect(req["Ad_Money2"]).to eq(diagnosis["Ad_Money2"])
              expect(req["Re_Money"]).to be_nil

              prev_response_json = response_json
              prev_response_json
            when 7
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq("99")
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
              prev_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::EmptyIcError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end
    end

    context "削除可能な剤がある" do
      context "削除可能な剤の削除指示を指定していない" do
        let(:patient_id) { 4 }
        let(:diagnosis) {
          {
            "Perform_Date" => "2017-07-31",
            "Perform_Time" => "10:30:00",
            "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
            "Diagnosis_Information" => {
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0009",
              },
              "Outside_Class" => "False", #	院内 False, 院外 True
              "Medical_Information" => {
                "OffTime" => "0",
                "Doctors_Fee" => "02",
                "Medical_Info" => [
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "101120010",
                        "Medication_Name" => "再診料",
                      },
                      {
                        "Medication_Code" => "112016070",
                        "Medication_Name" => "時間外対応加算１",
                      },
                      {
                        "Medication_Code" => "112015770",
                        "Medication_Name" => "明細書発行体制等加算",
                      }
                    ]
                  },
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "112011010",
                        "Medication_Name" => "外来管理加算",
                        "Medication_Number" => "1",
                      }
                    ]
                  },
                ],
              },
            },
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_delete.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            case count
            when 1
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq("karte_uid")
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
              expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
              expect(req["Orca_Uid"]).to eq("")
              req_diagnosis = req["Diagnosis_Information"]
              arg_diagnosis = diagnosis["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
                to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
              expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
              expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).
                to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
              prev_response_json
            when 2
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              req_diagnosis = req["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]).
                to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
              expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
              expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
                to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
              prev_response_json
            when 3
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to be_nil

              prev_response_json = response_json
              prev_response_json
            when 4
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq("99")
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
              prev_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::EmptyDeleteNumberInfoError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      end

      context "削除可能な剤の削除指示を指定する" do
        let(:patient_id) { 4 }
        let(:diagnosis) {
          {
            "Perform_Date" => "2017-07-31",
            "Perform_Time" => "10:30:00",
            "Base_Date" => "", # 収納発行日を診療日付以外とする時に設定
            "Diagnosis_Information" => {
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0009",
              },
              "Outside_Class" => "False", #	院内 False, 院外 True
              "Medical_Information" => {
                "OffTime" => "0",
                "Doctors_Fee" => "02",
                "Medical_Info" => [
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "101120010",
                        "Medication_Name" => "再診料",
                      },
                      {
                        "Medication_Code" => "112016070",
                        "Medication_Name" => "時間外対応加算１",
                      },
                      {
                        "Medication_Code" => "112015770",
                        "Medication_Name" => "明細書発行体制等加算",
                      }
                    ]
                  },
                  {
                    "Medical_Class" => "120",
                    "Medical_Class_Name" => "再診料",
                    "Medical_Class_Number" => "1",
                    "Medication_Info" => [
                      {
                        "Medication_Code" => "112011010",
                        "Medication_Name" => "外来管理加算",
                        "Medication_Number" => "1",
                      }
                    ]
                  },
                ],
              },
            },
            "Delete_Number_Info" => [
              { "Delete_Number" => "01" },
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
            count += 1
            case count
            when 1
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              expect(req["Request_Number"]).to eq("01")
              expect(req["Karte_Uid"]).to eq("karte_uid")
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(diagnosis["Perform_Date"])
              expect(req["Perform_Time"]).to eq(diagnosis["Perform_Time"])
              expect(req["Orca_Uid"]).to eq("")
              req_diagnosis = req["Diagnosis_Information"]
              arg_diagnosis = diagnosis["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
                to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
              expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
              expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).
                to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_01.json")
              prev_response_json
            when 2
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              req_diagnosis = req["Diagnosis_Information"]
              expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
              expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
              expect(req_diagnosis["HealthInsurance_Information"]).
                to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
              expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
              expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
                to eq(diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_02.json")
              prev_response_json
            when 3
              expect(path).to eq("/api21/medicalmodv32")

              req = body["medicalv3req2"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Invoice_Number"]).to be_nil
              expect(req["Select_Mode"]).to be_nil
              expect(req["Select_Answer"]).to be_nil

              prev_response_json = load_orca_api_response_json("api21_medicalmodv32_03_delete.json")
              prev_response_json
            when 4
              expect(path).to eq("/api21/medicalmodv33")

              req = body["medicalv3req3"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq(res_body["Response_Number"])
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Base_Date"]).to eq(diagnosis["Base_Date"])
              expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Perform_Time"]).to be_nil
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
              expect(req["Patient_Mode"]).to be_nil
              expect(req["Medical_Mode"]).to eq("1")
              expect(req["Delete_Number_Info"]).to eq(diagnosis["Delete_Number_Info"])
              expect(req["Ic_Code"]).to eq(diagnosis["Ic_Code"])
              expect(req["Ic_Money"]).to eq(diagnosis["Ic_Money"])
              expect(req["Ad_Money1"]).to eq(diagnosis["Ad_Money1"])
              expect(req["Ad_Money2"]).to eq(diagnosis["Ad_Money2"])
              expect(req["Re_Money"]).to be_nil

              prev_response_json = response_json
              prev_response_json
            when 5
              expect(path).to eq("/api21/medicalmodv31")

              req = body["medicalv3req1"]
              res_body = prev_response_json.first[1]
              expect(req["Request_Number"]).to eq("99")
              expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
              expect(req["Patient_ID"]).to eq(patient_id.to_s)
              expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
              expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

              prev_response_json = load_orca_api_response_json("api21_medicalmodv31_99.json")
              prev_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::PatientService::CreateMedicalPractice::EmptyIcError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end
    end
  end
end
