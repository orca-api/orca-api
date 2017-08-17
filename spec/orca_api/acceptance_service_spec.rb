require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::AcceptanceService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    let(:response_json) { load_orca_api_response_json("api01rv2_acceptlstv2_03.json") }

    it "ListResultを返すこと" do
      allow(orca_api).to receive(:call)
        .with("/api01rv2/acceptlstv2", params: { class: "03" }, body: { "acceptlstreq" => {} })
        .and_return(response_json)

      result = service.list
      expect(result.ok?).to be true
      expect(result.acceptance_date).to eq response_json["acceptlstres"]["Acceptance_Date"]
      expect(result.list).to eq response_json["acceptlstres"]["Acceptlst_Information"]
    end

    context "with arguments" do
      it "klass" do
        expect(orca_api).to receive(:call)
          .with("/api01rv2/acceptlstv2", params: { class: "01" }, body: { "acceptlstreq" => {} })
          .once
          .and_return(response_json)

        service.list(klass: '01')
      end

      it "base_date" do
        expect(orca_api).to receive(:call)
          .with("/api01rv2/acceptlstv2",
                params: { class: "03" },
                body: {
                  "acceptlstreq" => {
                    "Acceptance_Date" => "YYYY-MM-DD"
                  }
                })
          .once
          .and_return(response_json)

        service.list(base_date: "YYYY-MM-DD")
      end

      it "department_code" do
        expect(orca_api).to receive(:call)
          .with("/api01rv2/acceptlstv2",
                params: { class: "03" },
                body: {
                  "acceptlstreq" => {
                    "Department_Code" => "02"
                  }
                })
          .once
          .and_return(response_json)

        service.list(department_code: "02")
      end

      it "physician_code" do
        expect(orca_api).to receive(:call)
          .with("/api01rv2/acceptlstv2",
                params: { class: "03" },
                body: {
                  "acceptlstreq" => {
                    "Physician_Code" => "10002"
                  }
                })
          .once
          .and_return(response_json)

        service.list(physician_code: "10002")
      end

      it "medical_information" do
        expect(orca_api).to receive(:call)
          .with("/api01rv2/acceptlstv2",
                params: { class: "03" },
                body: {
                  "acceptlstreq" => {
                    "Medical_Information" => "02"
                  }
                })
          .once
          .and_return(response_json)

        service.list(medical_information: "02")
      end
    end
  end

  describe "#create" do
    let(:response_json) { load_orca_api_response_json("orca11_acceptmodv2_01.json") }

    it "リクエスト内容が正しいこと" do
      time = Time.parse("2017-08-09T12:34:56")

      expect(orca_api).to receive(:call)
        .with("/orca11/acceptmodv2",
              params: { class: "01" },
              body: {
                "acceptreq" => {
                  "Acceptance_Date" => "2017-08-09",
                  "Acceptance_Time" => "12:34:56",
                  "Patient_ID" => "0001",
                  "Department_Code" => "01",
                  "Physician_Code" => "10001",
                  "Medical_Information" => "01",
                  "HealthInsurance_Information" => {
                    "Insurance_Combination_Number" => "0001"
                  }
                }
              })
        .once
        .and_return(response_json)

      service.create(service
                       .new_builder
                       .accept_at(time)
                       .patient_id('0001')
                       .department_code('01')
                       .physician_code('10001')
                       .medical_information('01')
                       .insurance_combination_number('0001')
                       .to_h)
    end
  end

  describe "#destroy" do
    let(:response_json) { load_orca_api_response_json("orca11_acceptmodv2_02.json") }
    let(:acceptance_id) { SecureRandom.hex }
    let(:patient_id) { SecureRandom.hex }

    it "リクエスト内容が正しいこと" do
      expect(orca_api).to receive(:call)
        .with("/orca11/acceptmodv2",
              params: { class: "02" },
              body: {
                "acceptreq" => {
                  "Acceptance_Id" => acceptance_id,
                  "Patient_ID" => patient_id,
                }
              })
        .once
        .and_return(response_json)

      service.destroy(acceptance_id, patient_id)
    end
  end
end
