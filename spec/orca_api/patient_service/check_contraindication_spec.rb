# -*- coding: utf-8 -*-

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PatientService, "::CheckContraindication", patient_service_with_orca_api_mock: true do
  describe "#check_contraindication" do
    let(:patient_id) { 1 }
    let(:params) {
      {
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

    subject { patient_service.check_contraindication(patient_id, params) }

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
