require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::DiseaseService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    let(:args) {
      {
        "Patient_ID" => patient_id.to_s,
        "Base_Date" => "",
      }
    }

    subject { service.get(args) }

    def expect_api01rv2_diseasegetv2(path, params, body, args, response_json)
      expect(path).to eq("/api01rv2/diseasegetv2")
      expect(params).to eq({ "class" => "01" })
      expect(body["disease_inforeq"]).to eq(args)

      return_response_json(response_json)
    end

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).exactly(1) { |path, body:, params: nil|
        count += 1
        prev_response_json =
          case count
          when 1
            expect_api01rv2_diseasegetv2(path, params, body, args, response_json)
          end
        prev_response_json
      }
    end

    context "正常系" do
      let(:patient_id) { 1 }
      let(:response_json) { load_orca_api_response_json("api01rv2_diseasegetv2.json") }

      its("ok?") { is_expected.to be true }
      its(:disease_infores) { is_expected.to eq(response_json.first[1]["Disease_Infores"]) }
      its(:disease_information) { is_expected.to eq(response_json.first[1]["Disease_Information"]) }
    end

    context "異常系" do
      let(:patient_id) { 9999 }
      let(:response_json) { load_orca_api_response_json("api01rv2_diseasegetv2_10.json") }

      its("ok?") { is_expected.to be false }
    end
  end

  describe "#update" do
    let(:args) {
      {
        "Patient_ID" => "1",
        "Base_Month" => "",
        "Perform_Date" => "",
        "Perform_Time" => "",
        "Diagnosis_Information" => {
          "Department_Code" => "01",
        },
        "Disease_Information" => [
          {
            "Disease_Insurance_Class" => "05",
            "Disease_Code" => "",
            "Disease_Name" => "",
            "Disease_Single" => [
              {
                "Disease_Single_Code" => "5319009",
                "Disease_Single_Name" => "胃潰瘍",
              },
            ],
            "Disease_Supplement_Name" => "右膝",
            "Disease_Supplement_Single_Code" => [
              {
                "Disease_Supplement_Single_Code" => "",
              },
            ],
            "Disease_InOut" => "",
            "Disease_Category" => "",
            "Disease_SuspectedFlag" => "",
            "Disease_StartDate" => "2017-07-15",
            "Disease_EndDate" => "",
            "Disease_OutCome" => "",
            "Disease_Karte_Name" => "",
            "Disease_Class" => "",
            "Insurance_Combination_Number" => "",
            "Disease_Receipt_Print" => "",
            "Disease_Receipt_Print_Period" => "",
            "Insurance_Disease" => "False",
            "Discharge_Certificate" => "",
            "Main_Disease_Class" => "",
            "Sub_Disease_Class" => "",
          },
          {
            "Department_Code" => "01",
            "Disease_Name" => "両変形性膝関節症",
            "Disease_Single" => [
              {
                "Disease_Single_Code" => "ZZZ2057",
                "Disease_Single_Name" => "両",
              },
              {
                "Disease_Single_Code" => "7153018",
                "Disease_Single_Name" => "変形性膝関節症",
              },
            ],
            "Disease_StartDate" => "2017-06-01",
            "Insurance_Disease" => "False",
          },
          {
            "Department_Code" => "01",
            "Disease_Name" => "慢性心不全の疑い",
            "Disease_Single" => [
              {
                "Disease_Single_Code" => "4289018",
                "Disease_Single_Name" => "慢性心不全",
              },
              {
                "Disease_Single_Code" => "ZZZ8002",
                "Disease_Single_Name" => "の疑い",
              },
            ],
            "Disease_SuspectedFlag" => "S",
            "Disease_StartDate" => "2014-08-01",
            "Disease_OutCome" => "O", # 削除
            "Disease_Class" => "05",
            "Insurance_Disease" => "False",
          },
        ],
      }
    }

    subject { service.update(args) }

    def expect_orca22_diseasev3(path, body, args, response_json)
      expect(path).to eq("/orca22/diseasev3")
      expect(body["diseasereq"]).to eq(args)

      return_response_json(response_json)
    end

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).exactly(1) { |path, body:|
        count += 1
        prev_response_json =
          case count
          when 1
            expect_orca22_diseasev3(path, body, args, response_json)
          end
        prev_response_json
      }
    end

    context "正常系" do
      let(:response_json) { load_orca_api_response_json("orca22_diseasev3.json") }

      its("ok?") { is_expected.to be true }
      its(:disease_unmatch_information) { is_expected.to eq(response_json.first[1]["Disease_Unmatch_Information"]) }
    end

    context "異常系" do
      context "エラー" do
        let(:response_json) { load_orca_api_response_json("orca22_diseasev3_E42.json") }

        its("ok?") { is_expected.to be false }
        its(:disease_message_information) { is_expected.to eq(response_json.first[1]["Disease_Message_Information"]) }
      end

      context "他端末使用中" do
        let(:response_json) { load_orca_api_response_json("orca22_diseasev3_E90.json") }

        its("ok?") { is_expected.to be false }
      end
    end
  end
end
