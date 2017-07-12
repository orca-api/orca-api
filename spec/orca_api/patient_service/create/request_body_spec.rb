# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService::Create::RequestBody do
  let(:patient_information) {
    json = load_orca_api_response_json("orca12_patientmodv31_01_new.json")
    OrcaApi::PatientInformation.new(json.first[1]["Patient_Information"])
  }
  let(:request_number) { "01" }
  let(:orca_uid) { "" }
  let(:select_answer) { "" }
  let(:request_body) {
    described_class.new(
      karte_uid: "karte_uid",
      patient_information: patient_information,
      request_number: request_number,
      orca_uid: orca_uid,
      select_answer: select_answer
    )
  }

  describe "#empty?" do
    subject { request_body.empty? }

    it { is_expected.to be false }
  end

  describe "#to_json" do
    subject { JSON.parse(request_body.to_json) }

    let(:expected_patient_information) {
      {
        "WholeName" => "東京　太郎",
        "WholeName_inKana" => "トウキョウ　タロウ",
        "BirthDate" => "1965-04-04",
        "Sex" => "1",
        "HouseHolder_WholeName" => "東京　太郎",
        "Relationship" => "世帯主",
        "Occupation" => "警備員",
        "NickName" => "ニックネーム",
        "CellularNumber" => "012-3456-7890",
        "FaxNumber" => "01-2345-6789",
        "EmailAddress" => "test@example.com",
        "Home_Address_Information" => {
          "Address_ZipCode" => "6900051",
          "WholeAddress1" => "島根県松江市横浜町",
          "WholeAddress2" => "１１５５",
          "PhoneNumber1" => "0852-22-2222",
          "PhoneNumber2" => "0852-44-4444",
        },
        "WorkPlace_Information" => {
          "WholeName" => "島根銀行株式会社",
          "Address_ZipCode" => "6900015",
          "WholeAddress1" => "島根県松江市上乃木",
          "WholeAddress2" => "１２３４５６",
          "PhoneNumber" => "0852-33-3333",
        },
        "Contact_Information" => {
          "WholeName" => "島根銀行株式会社",
          "Relationship" => "勤務先",
          "Address_ZipCode" => "6900015",
          "WholeAddress1" => "島根県松江市上乃木",
          "WholeAddress2" => "１２３４５６",
          "PhoneNumber1" => "0852-33-3333",
          "PhoneNumber2" => "0852-55-5555",
        },
        "Home2_Information" => {
          "WholeName" => "実家",
          "Address_ZipCode" => "6900099",
          "WholeAddress1" => "島根県松江市沖縄町",
          "WholeAddress2" => "５５１１",
          "PhoneNumber" => "0852-99-9999",
        },
        "Contraindication1" => "　",
        "Contraindication2" => "　",
        "Allergy1" => "えび",
        "Allergy2" => "かに",
        "TestPatient_Flag" => "0",
        "Death_Flag" => "0",
        "Reduction_Reason" => "00",
        "Discount" => "00",
        "Condition1" => "00",
        "Condition2" => "00",
        "Condition3" => "00",
      }
    }

    context "Request_Number=01" do
      let(:request_number) { "01" }
      let(:orca_uid) { "" }
      let(:select_answer) { "" }

      let(:expected) {
        {
          "patientmodreq" => {
            "Request_Number" => "01",
            "Karte_Uid" => "karte_uid",
            "Patient_ID" => "*",
            "Patient_Mode" => "New",
            "Orca_Uid" => "",
            "Select_Answer" => "",
            "Patient_Information" => expected_patient_information,
          }
        }
      }

      it { is_expected.to eq(expected) }
    end

    context "Request_Number=02" do
      let(:request_number) { "02" }
      let(:orca_uid) { "orca_uid" }
      let(:select_answer) { "Ok" }

      let(:expected) {
        {
          "patientmodreq" => {
            "Request_Number" => "02",
            "Karte_Uid" => "karte_uid",
            "Patient_ID" => "*",
            "Patient_Mode" => "New",
            "Orca_Uid" => "orca_uid",
            "Select_Answer" => "Ok",
            "Patient_Information" => expected_patient_information,
          }
        }
      }

      it { is_expected.to eq(expected) }
    end
  end
end
