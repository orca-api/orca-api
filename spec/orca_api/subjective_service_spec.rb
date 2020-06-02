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

    it "保険組合せ情報を指定したときでもAPI呼び出しが正しいこと" do
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
                "Subjectives_Code" => "foobarbaz",
                "HealthInsurance_Information" => {
                  "InsuranceProvider_Class" => "009",
                  "PublicInsurance_Information" => [
                    {
                      "PublicInsurance_Class" => "051"
                    }
                  ]
                }
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
        "HealthInsurance_Information" => {
          "InsuranceProvider_Class" => "009",
          "PublicInsurance_Information" => [
            {
              "PublicInsurance_Class" => "051"
            }
          ]
        }
      }
      result = service.create params
      expect(result.ok?).to be true
    end

    it "保険組合せ情報がまったくない場合でもAPI呼び出しが正しいこと" do
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
                "Subjectives_Code" => "foobarbaz",
                "HealthInsurance_Information" => {
                  "InsuranceProvider_Class" => "009"
                }
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
        "HealthInsurance_Information" => {
          "InsuranceProvider_Class" => "009"
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

    it "保険組合せ情報を指定したときでもAPI呼び出しが正しいこと" do
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
                "Subjectives_Detail_Record" => "07",
                "HealthInsurance_Information" => {
                  "InsuranceProvider_Class" => "009",
                  "PublicInsurance_Information" => [
                    {
                      "PublicInsurance_Class" => "051"
                    }
                  ]
                }
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
        "HealthInsurance_Information" => {
          "InsuranceProvider_Class" => "009",
          "PublicInsurance_Information" => [
            {
              "PublicInsurance_Class" => "051"
            }
          ]
        }
      }
      result = service.destroy params
      expect(result.ok?).to be true
    end
  end

  describe "#list" do
    it "API呼び出しが正しいこと" do
      expect_orca_api_call(
        [
          {
            path: "/api01rv2/subjectiveslstv2",
            body: {
              "subjectiveslstreq" => {
                "Request_Number" => "01",
                "Patient_ID" => "00001"
              }
            },
            response: {
              "subjectiveslstres" => {
                "Api_Result" => "WK1",
                "Patient_Information" => { "Patient_ID" => "00001" },
                "Perform_Date" => "2018-06",
                "Subjectives_Information" => [
                  {
                    "InOut" => "O",
                    "Department_Code" => "00",
                    "HealthInsurance_Information" => {
                      "Insurance_Combination_Number" => "0001"
                    },
                    "Subjectives_Detail_Record" => "07",
                    "Subjectives_Number" => "01"
                  },
                  {
                    "InOut" => "O",
                    "Department_Code" => "00",
                    "HealthInsurance_Information" => {
                      "Insurance_Combination_Number" => "0001"
                    },
                    "Subjectives_Detail_Record" => "08",
                    "Subjectives_Number" => "01"
                  },
                  {
                    "InOut" => "O",
                    "Department_Code" => "00",
                    "HealthInsurance_Information" => {
                      "Insurance_Combination_Number" => "0002"
                    },
                    "Perform_Day" => "20",
                    "Subjectives_Detail_Record" => "03",
                    "Subjectives_Number" => "01"
                  }
                ]
              }
            }.to_json
          },
          {
            path: "/api01rv2/subjectiveslstv2",
            body: {
              "subjectiveslstreq" => {
                "Request_Number" => "02",
                "InOut" => "O",
                "Patient_ID" => "00001",
                "Perform_Date" => "2018-06",
                "Department_Code" => "00",
                "Insurance_Combination_Number" => "0001",
                "Subjectives_Detail_Record" => "07",
                "Subjectives_Number" => "01"
              }
            },
            response: {
              "subjectiveslstres" => {
                "Api_Result" => "000",
                "Subjectives_Code_Information" => {
                  "Subjectives_Code" => "いろはにほへとちりぬるを"
                }
              }
            }.to_json
          },
          {
            path: "/api01rv2/subjectiveslstv2",
            body: {
              "subjectiveslstreq" => {
                "Request_Number" => "02",
                "InOut" => "O",
                "Patient_ID" => "00001",
                "Perform_Date" => "2018-06",
                "Department_Code" => "00",
                "Insurance_Combination_Number" => "0001",
                "Subjectives_Detail_Record" => "08",
                "Subjectives_Number" => "01"
              }
            },
            response: {
              "subjectiveslstres" => {
                "Api_Result" => "000",
                "Subjectives_Code_Information" => {
                  "Subjectives_Code" => "わかよたれそつねならむ"
                }
              }
            }.to_json
          },
          {
            path: "/api01rv2/subjectiveslstv2",
            body: {
              "subjectiveslstreq" => {
                "Request_Number" => "02",
                "InOut" => "O",
                "Patient_ID" => "00001",
                "Perform_Date" => "2018-06",
                "Department_Code" => "00",
                "Insurance_Combination_Number" => "0002",
                "Subjectives_Detail_Record" => "03",
                "Subjectives_Number" => "01",
                "Perform_Day" => "20"
              }
            },
            response: {
              "subjectiveslstres" => {
                "Api_Result" => "000",
                "Subjectives_Code_Information" => {
                  "Subjectives_Code" => "うゐのおくやまけふこえて"
                }
              }
            }.to_json
          }
        ],
        binding
      )

      params = {
        "Patient_ID" => "00001"
      }
      result = service.list params
      expect(result.ok?).to be true

      expect(result.subjectives_information).to eq([
                                                     {
                                                       "InOut" => "O",
                                                       "Department_Code" => "00",
                                                       "HealthInsurance_Information" => {
                                                         "Insurance_Combination_Number" => "0001"
                                                       },
                                                       "Subjectives_Detail_Record" => "07",
                                                       "Subjectives_Number" => "01",
                                                       "Subjectives_Code" => "いろはにほへとちりぬるを",
                                                     },
                                                     {
                                                       "InOut" => "O",
                                                       "Department_Code" => "00",
                                                       "HealthInsurance_Information" => {
                                                         "Insurance_Combination_Number" => "0001"
                                                       },
                                                       "Subjectives_Detail_Record" => "08",
                                                       "Subjectives_Number" => "01",
                                                       "Subjectives_Code" => "わかよたれそつねならむ",
                                                     },
                                                     {
                                                       "InOut" => "O",
                                                       "Department_Code" => "00",
                                                       "HealthInsurance_Information" => {
                                                         "Insurance_Combination_Number" => "0002"
                                                       },
                                                       "Perform_Day" => "20",
                                                       "Subjectives_Detail_Record" => "03",
                                                       "Subjectives_Number" => "01",
                                                       "Subjectives_Code" => "うゐのおくやまけふこえて",
                                                     }
                                                   ])
    end
  end
end
