# coding: utf-8

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::MedicalPracticeService, orca_api_mock: true do
  let(:service) { OrcaApi::MedicalPracticeService.new(orca_api) }

  def return_response_json(response_json)
    if response_json.is_a?(String)
      load_orca_api_response_json(response_json)
    else
      response_json
    end
  end

  def expect_api21_medicalmodv31_01(path, body, response_json = "api21_medicalmodv31_01.json")
    expect(path).to eq("/api21/medicalmodv31")

    req = body["medicalv3req1"]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    expect(req["Patient_ID"]).to eq(params["Patient_ID"])
    expect(req["Perform_Date"]).to eq(params["Perform_Date"])
    expect(req["Perform_Time"]).to eq(params["Perform_Time"])
    expect(req["Orca_Uid"]).to eq("")
    req_diagnosis = req["Diagnosis_Information"]
    arg_diagnosis = params["Diagnosis_Information"]
    expect(req_diagnosis["Department_Code"]).to eq(arg_diagnosis["Department_Code"])
    expect(req_diagnosis["Physician_Code"]).to eq(arg_diagnosis["Physician_Code"])
    expect(req_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"]).
      to eq(arg_diagnosis["HealthInsurance_Information"]["Insurance_Combination_Number"])
    expect(req_diagnosis["Medical_Information"]["OffTime"]).to eq(arg_diagnosis["Medical_Information"]["OffTime"])
    expect(req_diagnosis["Medical_Information"]["Doctors_Fee"]).to eq(arg_diagnosis["Medical_Information"]["Doctors_Fee"])

    return_response_json(response_json)
  end

  def expect_api21_medicalmodv32_02(path, body, prev_response_json, response_json = "api21_medicalmodv32_02.json")
    expect(path).to eq("/api21/medicalmodv32")

    req = body["medicalv3req2"]
    req_diagnosis = req["Diagnosis_Information"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    if params["Invoice_Number"]
      expect(req["Perform_Time"]).to eq(params["Perform_Time"])
      expect(req["Patient_Mode"]).to eq("Modify")
      expect(req["Invoice_Number"]).to eq(params["Invoice_Number"])
      expect(req_diagnosis["HealthInsurance_Information"]).to eq(res_body["HealthInsurance_Information"])
      expect(req_diagnosis["Medical_OffTime"]).to eq(params["Diagnosis_Information"]["Medical_Information"]["OffTime"])
    else
      expect(req["Patient_Mode"]).to be_nil
      expect(req["Invoice_Number"]).to be_nil
      expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
      expect(req_diagnosis["HealthInsurance_Information"]).
        to eq(res_body["Patient_Information"]["HealthInsurance_Information"])
      expect(req_diagnosis["Medical_OffTime"]).to eq(res_body["Medical_OffTime"])
    end
    expect(req_diagnosis["Department_Code"]).to eq(res_body["Department_Code"])
    expect(req_diagnosis["Physician_Code"]).to eq(res_body["Physician_Code"])
    expect(req_diagnosis["Medical_Information"]["Medical_Info"]).
      to eq(params["Diagnosis_Information"]["Medical_Information"]["Medical_Info"])

    return_response_json(response_json)
  end

  def expect_api21_medicalmodv32_03(path, body, prev_response_json,
                                    answer_index = nil, response_json = "api21_medicalmodv32_03.json")
    expect(path).to eq("/api21/medicalmodv32")

    req = body["medicalv3req2"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
    expect(req["Perform_Time"]).to eq(res_body["Perform_Time"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    if params["Invoice_Number"]
      expect(req["Patient_Mode"]).to eq("Modify")
      expect(req["Invoice_Number"]).to eq(params["Invoice_Number"])
    else
      expect(req["Patient_Mode"]).to be_nil
      expect(req["Invoice_Number"]).to be_nil
    end
    expect(req["Select_Mode"]).to be_nil
    if answer_index
      expect(req["Select_Answer"]).to eq(params["Medical_Select_Information"][answer_index]["Select_Answer"])
    else
      expect(req["Select_Answer"]).to be_nil
    end

    return_response_json(response_json)
  end

  def expect_api21_medicalmodv33_04(path, body, prev_response_json, response_json = "api21_medicalmodv33_04.json")
    expect(path).to eq("/api21/medicalmodv33")

    req = body["medicalv3req3"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
    expect(req["Perform_Time"]).to be_nil
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    if params["Invoice_Number"]
      expect(req["Patient_Mode"]).to eq("Modify")
    else
      expect(req["Patient_Mode"]).to be_nil
    end

    expect(req["Base_Date"]).to eq(params["Base_Date"])

    if params["Delete_Number_Info"]
      expect(req["Medical_Mode"]).to eq("1")
    else
      expect(req["Medical_Mode"]).to be_nil
    end
    expect(req["Delete_Number_Info"]).to eq(params["Delete_Number_Info"])

    %w(Ic_Code Ic_Request_Code Ic_All_Code Cd_Information Print_Information).each do |name|
      expect(req[name]).to eq(params[name])
    end

    return_response_json(response_json)
  end

  def expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json = "api21_medicalmodv33_05.json")
    expect(path).to eq("/api21/medicalmodv33")

    req = body["medicalv3req3"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
    expect(req["Perform_Time"]).to be_nil
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    if params["Invoice_Number"]
      expect(req["Patient_Mode"]).to eq("Modify")
    else
      expect(req["Patient_Mode"]).to be_nil
    end

    expect(req["Base_Date"]).to eq(params["Base_Date"])

    %w(Base_Date Ic_Code Ic_Request_Code Ic_All_Code Cd_Information Print_Information).each do |name|
      expect(req[name]).to eq(params[name])
    end

    return_response_json(response_json)
  end

  def expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
    expect(path).to eq("/api21/medicalmodv31")

    req = body["medicalv3req1"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response_json("api21_medicalmodv31_99.json")
  end

  def expect_api21_medicalmodv34_01(path, body, patient_mode, response_json)
    expect(path).to eq("/api21/medicalmodv34")

    req = body["medicalv3req4"]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    expect(req["Orca_Uid"]).to eq("")
    expect(req["Patient_Mode"]).to eq(patient_mode)
    %w(Patient_ID Perform_Date Invoice_Number Department_Code Insurance_Combination_Number Sequential_Number).each do |name|
      expect(req[name]).to eq(params[name])
    end

    return_response_json(response_json)
  end

  def expect_api21_medicalmodv34_02(path, body, prev_response_json, response_json)
    expect(path).to eq("/api21/medicalmodv34")

    req = body["medicalv3req4"]
    res_body = prev_response_json.first[1]

    expect(req["Request_Number"]).to eq("02")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    %w(Orca_Uid Perform_Date Invoice_Number Department_Code Sequential_Number).each do |name|
      expect(req[name]).to eq(res_body[name])
    end
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Insurance_Combination_Number"]).to eq(res_body["HealthInsurance_Information"]["Insurance_Combination_Number"])
    expect(req["Select_Answer"]).to eq("Ok")

    return_response_json(response_json)
  end

  def expect_api21_medicalmodv34_99_call(path, body, prev_response_json)
    expect(path).to eq("/api21/medicalmodv34")

    req = body["medicalv3req4"]
    res_body = prev_response_json.first[1]
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Perform_Date"]).to eq(res_body["Perform_Date"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response_json("api21_medicalmodv34_99.json")
  end

  describe "#get_examination_fee" do
    let(:params) {
      {
        "Patient_ID" => "4",
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

    subject { service.get_examination_fee(params) }

    context "患者情報をロックする" do
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv31_01.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv31_01(path, body, response_json)
            when 2
              expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }

      context "Perform_Dateが未指定であるためレスポンスがW00" do
        let(:params) {
          super().tap { |d| d.delete("Perform_Date") }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv31_01_W00.json") }

        its("ok?") { is_expected.to be true }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      end

      context "別端末使用中以外のエラー" do
        let(:response_json) {
          super().tap { |json| json.first[1]["Api_Result"] = "E20" }
        }

        its("ok?") { is_expected.to be false }
      end
    end

    context "患者情報をロックしない" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv31_01(path, body, response_json)
            end
          prev_response_json
        }
      end

      context "患者情報が未指定" do
        let(:params) {
          super().tap { |h|
            h.delete("Patient_ID")
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv31_01_E01.json") }

        its("ok?") { is_expected.to be false }
      end
    end
  end

  describe "#calc_medical_practice_fee" do
    let(:params) {
      {
        "Patient_ID" => "4",
        "Perform_Date" => "2017-07-31",
        "Perform_Time" => "10:30:00",
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

    subject { service.calc_medical_practice_fee(params) }

    context "選択項目も削除可能な剤もない" do
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv31_01(path, body)
            when 2
              expect_api21_medicalmodv32_02(path, body, prev_response_json)
            when 3
              expect_api21_medicalmodv32_03(path, body, prev_response_json)
            when 4
              expect_api21_medicalmodv33_04(path, body, prev_response_json, response_json)
            when 5
              expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
            end
        }
      end

      its("ok?") { is_expected.to be true }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
    end

    context "選択項目がある" do
      context "選択項目を指定していない" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_select.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, response_json)
              when 4
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::MedicalPracticeService::UnselectedError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:medical_select_information) { is_expected.to eq(response_json.first[1]["Medical_Select_Information"]) }
      end

      context "選択項目を指定する" do
        let(:params) {
          super().tap { |d|
            d["Medical_Select_Information"] = [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(6) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_select.json")
              when 4
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 0)
              when 5
                expect_api21_medicalmodv33_04(path, body, prev_response_json, response_json)
              when 6
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end

      context "選択項目が2つあるが、1つしか指定していない" do
        let(:params) {
          super().tap { |d|
            d["Medical_Select_Information"] = [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_select2.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_select.json")
              when 4
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 0, response_json)
              when 5
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::MedicalPracticeService::UnselectedError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:medical_select_information) { is_expected.to eq(response_json.first[1]["Medical_Select_Information"]) }
      end

      context "2つの選択項目を指定する" do
        let(:params) {
          super().tap { |d|
            d["Medical_Select_Information"] = [
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
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(7) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_select.json")
              when 4
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 0, "api21_medicalmodv32_03_select2.json")
              when 5
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 1)
              when 6
                expect_api21_medicalmodv33_04(path, body, prev_response_json, response_json)
              when 7
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end
    end

    context "削除可能な剤がある" do
      context "削除可能な剤の削除指示を指定していない" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_delete.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, response_json)
              when 4
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::MedicalPracticeService::EmptyDeleteNumberInfoError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      end

      context "削除可能な剤の削除指示を指定する" do
        let(:params) {
          super().tap { |d|
            d["Delete_Number_Info"] = [
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
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_delete.json")
              when 4
                expect_api21_medicalmodv33_04(path, body, prev_response_json, response_json)
              when 5
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end
    end

    context "訂正時" do
      let(:params) {
        super().tap { |d|
          d["Invoice_Number"] = "0000853"
        }
      }

      let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_04_modify.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv34_01(path, body, "Modify", "api21_medicalmodv34_01_modify.json")
            when 2
              expect_api21_medicalmodv32_02(path, body, prev_response_json, "api21_medicalmodv32_02_modify.json")
            when 3
              expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_modify.json")
            when 4
              expect_api21_medicalmodv33_04(path, body, prev_response_json, response_json)
            when 5
              expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
            end
        }
      end

      its("ok?") { is_expected.to be true }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
    end
  end

  describe "#create" do
    let(:params) {
      {
        "Patient_ID" => "4",
        "Perform_Date" => "2017-07-31",
        "Perform_Time" => "10:30:00",
        "Diagnosis_Information" => {
          "Department_Code" => "01",
          "Physician_Code" => "10001",
          "HealthInsurance_Information" => {
            "Insurance_Combination_Number" => "0009",
          },
          "Outside_Class" => "False",
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
        "Base_Date" => "",
        "Ic_Code" => "1",
        "Ic_Request_Code" => "2",
        "Ic_All_Code" => "",
        "Cd_Information" => {
          "Ad_Money1" => "0",
          "Ad_Money2" => "0",
          "Ic_Money" => "2057",
          "Re_Money" => "",
        },
        "Print_Information" => {
          "Print_Prescription_Class" => "0",
          "Print_Invoice_Receipt_Class" => "0",
          "Print_Statement_Class" => "0",
          "Print_Medicine_Information_Class" => "0",
          "Print_Medication_Note_Class" => "0",
          "Print_Appointment_Form_Class" => "0",
        },
      }
    }

    subject { service.create(params) }

    context "正常終了" do
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_05.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv31_01(path, body)
            when 2
              expect_api21_medicalmodv32_02(path, body, prev_response_json)
            when 3
              expect_api21_medicalmodv32_03(path, body, prev_response_json)
            when 4
              expect_api21_medicalmodv33_04(path, body, prev_response_json)
            when 5
              expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json)
            end
        }
      end

      its("ok?") { is_expected.to be true }
      its(:invoice_number) { is_expected.to eq(response_json.first[1]["Invoice_Number"]) }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
    end

    context "選択項目がある" do
      context "選択項目を指定していない" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_select.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, response_json)
              when 4
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::MedicalPracticeService::UnselectedError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:medical_select_information) { is_expected.to eq(response_json.first[1]["Medical_Select_Information"]) }
      end

      context "選択項目を指定する" do
        let(:params) {
          super().tap { |d|
            d["Medical_Select_Information"] = [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_05.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(6) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_select.json")
              when 4
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 0)
              when 5
                expect_api21_medicalmodv33_04(path, body, prev_response_json)
              when 6
                expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json)
              end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:invoice_number) { is_expected.to eq(response_json.first[1]["Invoice_Number"]) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end

      context "選択項目が2つあるが、1つしか指定していない" do
        let(:params) {
          super().tap { |d|
            d["Medical_Select_Information"] = [
              {
                "Medical_Select" => "0113",
                "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。",
                "Select_Answer" => "No",
              },
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_select2.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_select.json")
              when 4
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 0, response_json)
              when 5
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::MedicalPracticeService::UnselectedError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:medical_select_information) { is_expected.to eq(response_json.first[1]["Medical_Select_Information"]) }
      end

      context "2つの選択項目を指定する" do
        let(:params) {
          super().tap { |d|
            d["Medical_Select_Information"] = [
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
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_05.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(7) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_select.json")
              when 4
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 0, "api21_medicalmodv32_03_select2.json")
              when 5
                expect_api21_medicalmodv32_03(path, body, prev_response_json, 1)
              when 6
                expect_api21_medicalmodv33_04(path, body, prev_response_json)
              when 7
                expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json)
              end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:invoice_number) { is_expected.to eq(response_json.first[1]["Invoice_Number"]) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end
    end

    context "削除可能な剤がある" do
      context "削除可能な剤の削除指示を指定していない" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv32_03_delete.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, response_json)
              when 4
                expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
              end
          }
        end

        its("ok?") { is_expected.to be false }
        it { is_expected.to be_kind_of(OrcaApi::MedicalPracticeService::EmptyDeleteNumberInfoError) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      end

      context "削除可能な剤の削除指示を指定する" do
        let(:params) {
          super().tap { |d|
            d["Delete_Number_Info"] = [
              { "Delete_Number" => "01" },
            ]
          }
        }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_05.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv31_01(path, body)
              when 2
                expect_api21_medicalmodv32_02(path, body, prev_response_json)
              when 3
                expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_delete.json")
              when 4
                expect_api21_medicalmodv33_04(path, body, prev_response_json)
              when 5
                expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json)
              end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:invoice_number) { is_expected.to eq(response_json.first[1]["Invoice_Number"]) }
        its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
        its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
      end
    end

    context "訂正時" do
      let(:params) {
        super().tap { |d|
          d["Invoice_Number"] = "0000853"
        }
      }

      let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_05_modify.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(5) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv34_01(path, body, "Modify", "api21_medicalmodv34_01_modify.json")
            when 2
              expect_api21_medicalmodv32_02(path, body, prev_response_json, "api21_medicalmodv32_02_modify.json")
            when 3
              expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_modify.json")
            when 4
              expect_api21_medicalmodv33_04(path, body, prev_response_json, "api21_medicalmodv33_04_modify.json")
            when 5
              expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json)
            end
        }
      end

      its("ok?") { is_expected.to be true }
      its(:invoice_number) { is_expected.to eq(response_json.first[1]["Invoice_Number"]) }
      its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
      its(:cd_information) { is_expected.to eq(response_json.first[1]["Cd_Information"]) }
    end

    context "訂正時にエラー" do
      let(:params) {
        super().tap { |d|
          d["Invoice_Number"] = "0000853"
          d["Cd_Information"]["Re_Money"] = "0"
        }
      }

      let(:response_json) { load_orca_api_response_json("api21_medicalmodv33_05_modify_error.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(6) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv34_01(path, body, "Modify", "api21_medicalmodv34_01_modify.json")
            when 2
              expect_api21_medicalmodv32_02(path, body, prev_response_json, "api21_medicalmodv32_02_modify.json")
            when 3
              expect_api21_medicalmodv32_03(path, body, prev_response_json, nil, "api21_medicalmodv32_03_modify.json")
            when 4
              expect_api21_medicalmodv33_04(path, body, prev_response_json, "api21_medicalmodv33_04_modify.json")
            when 5
              expect_api21_medicalmodv33_05(path, body, prev_response_json, response_json)
            when 6
              expect_unlock_api21_medicalmodv31(path, body, prev_response_json)
            end
        }
      end

      its("ok?") { is_expected.to be false }
    end
  end

  describe "#get" do
    let(:params) {
      {
        "Patient_ID" => "4",
        "Perform_Date" => "2017-08-29",
        "Invoice_Number" => "0000857",
        "Department_Code" => "",
        "Insurance_Combination_Number" => "",
        "Sequential_Number" => "",
      }
    }

    subject { service.get(params) }

    context "正常系" do
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_modify.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv34_01(path, body, "Modify", response_json)
            when 2
              expect_api21_medicalmodv34_99_call(path, body, prev_response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }

      %w(
        Department_Code Department_Name Sequential_Number Physician_Code Physician_WholeName HealthInsurance_Information
        Medical_Information
      ).each do |name|
        its(OrcaApi::Result.json_name_to_attr_name(name).to_sym) { is_expected.to eq(response_json.first[1][name]) }
      end
    end

    context "異常系" do
      context "他端末使用中" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_locked.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv34_01(path, body, "Modify", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end

      context "受診履歴が存在しない" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_E22.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv34_01(path, body, "Modify", response_json)
              when 2
                expect_api21_medicalmodv34_99_call(path, body, prev_response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end

      context "患者番号が未指定" do
        let(:params) { {} }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_E01.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv34_01(path, body, "Modify", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end
    end
  end

  describe "#destroy" do
    let(:params) {
      {
        "Patient_ID" => "4",
        "Perform_Date" => "2017-08-29",
        "Invoice_Number" => "0000857",
        "Department_Code" => "",
        "Insurance_Combination_Number" => "",
        "Sequential_Number" => "",
      }
    }

    subject { service.destroy(params) }

    context "正常系" do
      let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_02_delete.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_api21_medicalmodv34_01(path, body, "Delete", "api21_medicalmodv34_01_delete.json")
            when 2
              expect_api21_medicalmodv34_02(path, body, prev_response_json, response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }

      %w(
        Department_Code Sequential_Number HealthInsurance_Information
      ).each do |name|
        its(OrcaApi::Result.json_name_to_attr_name(name).to_sym) { is_expected.to eq(response_json.first[1][name]) }
      end
    end

    context "異常系" do
      context "他端末使用中" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_locked.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv34_01(path, body, "Delete", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end

      context "受診履歴が存在しない" do
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_E22.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv34_01(path, body, "Delete", response_json)
              when 2
                expect_api21_medicalmodv34_99_call(path, body, prev_response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end

      context "患者番号が未指定" do
        let(:params) { {} }
        let(:response_json) { load_orca_api_response_json("api21_medicalmodv34_01_E01.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_api21_medicalmodv34_01(path, body, "Delete", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end
    end
  end

  describe "#check_contraindication" do
    let(:patient_id) { 1 }
    let(:params) {
      {
        "Patient_ID" => patient_id.to_s,
        "Perform_Month" => "2017-08", # 診療年月(省略可能。未設定はシステム日付)
        "Check_Term" => "", # チェック月数(省略可能。未設定はシステム管理の相互作用チェック期間)
        # チェック薬剤情報(最大30件)
        "Medical_Information" => [
          {
            "Medication_Code" => "620002477", # 薬剤コード
            # "Medication_Name" => "ベザレックスＳＲ錠１００　１００ｍｇ", # 薬剤名称(省略可能)
          },
          {
            "Medication_Code" => "610422262", # 薬剤コード
            # "Medication_Name" => "クレストール錠２．５ｍｇ", # 薬剤名称(省略可能)
          },
        ],
      }
    }
    let(:response_json) { load_orca_api_response_json("api01rv2_contraindicationcheckv2.json") }

    subject { service.check_contraindication(params) }

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
        count += 1
        prev_response_json =
          case count
          when 1
            expect(path).to eq("/api01rv2/contraindicationcheckv2")

            req = body["contraindication_checkreq"]
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Perform_Month"]).to eq(params["Perform_Month"])
            expect(req["Check_Term"]).to eq(params["Check_Term"])
            expect(req["Medical_Information"]).to eq(params["Medical_Information"])

            response_json
          end
        prev_response_json
      }
    end

    its("ok?") { is_expected.to be true }
    its(:perform_month) { is_expected.to eq(response_json.first[1]["Perform_Month"]) }
    its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
    its(:medical_information) { is_expected.to eq(response_json.first[1]["Medical_Information"]) }
    its(:symptom_information) { is_expected.to eq(response_json.first[1]["Symptom_Information"]) }
  end
end
