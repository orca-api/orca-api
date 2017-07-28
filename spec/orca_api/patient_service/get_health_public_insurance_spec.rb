# -*- coding: utf-8 -*-

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::GetHealthPublicInsurance" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#get_health_public_insurance" do
    let(:patient_id) { 1 }
    let(:response_json) { load_orca_api_response_json("orca12_patientmodv32_01.json") }

    subject { patient_service.get_health_public_insurance(patient_id) }

    before do
      count = 0
      expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).twice { |_, body:|
        req = body["patientmodreq"]

        count += 1
        case count
        when 1
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

          response_json
        when 2
          expect(req["Request_Number"]).to eq("99")
          res01 = response_json.first[1]
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          expect(req["Patient_Information"]).to eq(res01["Patient_Information"])

          load_orca_api_response_json("orca12_patientmodv32_99.json")
        end
      }
    end

    describe "health_public_insurance" do
      subject { super().health_public_insurance }

      %w(
        Patient_Information
        HealthInsurance_Information
        PublicInsurance_Information
        HealthInsurance_Combination_Information
      ).each do |name|
        describe "[\"#{name}\"]" do
          subject { super()[name] }

          it { is_expected.to eq(response_json.first[1][name]) }
        end
      end
    end
  end
end
