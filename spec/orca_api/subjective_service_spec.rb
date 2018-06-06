require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::SubjectiveService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#create" do
    it "API呼び出しが正しいこと" do
      expect_orca_api_call(
        [
          {
            path: "/orca25/subjectivesv2",
            params: { "class" => "01" },
            body: {
              "subjectivesmodreq" => {
                "Patient_ID" => "00001",
                "InOut" => "O",
                "Perform_Date" => "2018-06",
                "Department_Code" => "00",
                "Insurance_Combination_Number" => "0001",
                "Subjectives_Detail_Record" => "07",
                "Subjectives_Code" => "foobarbaz"
              }
            },
            result: "orca25_subjectivesv2_01.json"
          }
        ],
        binding
      )

      params = {
        "Patient_ID" => "00001",
        "InOut" => "O",
        "Perform_Date" => "2018-06",
        "Department_Code" => "00",
        "Insurance_Combination_Number" => "0001",
        "Subjectives_Detail_Record" => "07",
        "Subjectives_Code" => "foobarbaz",
        "UnknownParameter" => "UnknownValue",
        "HealthInsurance_Information" => {
          "PublicInsurance_Information" => {
          }
        }
      }
      result = service.create params
      expect(result.ok?).to be true
    end
  end

  describe "#destroy" do
    it "API呼び出しが正しいこと" do
      expect_orca_api_call(
        [
          {
            path: "/orca25/subjectivesv2",
            params: { "class" => "02" },
            body: {
              "subjectivesmodreq" => {
                "Patient_ID" => "00001",
                "InOut" => "O",
                "Perform_Date" => "2018-06",
                "Department_Code" => "00",
                "Insurance_Combination_Number" => "0001",
                "Subjectives_Detail_Record" => "07"
              }
            },
            result: "orca25_subjectivesv2_02.json"
          }
        ],
        binding
      )

      params = {
        "Patient_ID" => "00001",
        "InOut" => "O",
        "Perform_Date" => "2018-06",
        "Department_Code" => "00",
        "Insurance_Combination_Number" => "0001",
        "Subjectives_Detail_Record" => "07",
        "UnknownParameter" => "UnknownValue",
        "HealthInsurance_Information" => {
          "PublicInsurance_Information" => {
          }
        }
      }
      result = service.destroy params
      expect(result.ok?).to be true
    end
  end
end
