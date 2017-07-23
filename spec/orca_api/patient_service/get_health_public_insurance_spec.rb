# -*- coding: utf-8 -*-

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::GetHealthPublicInsurance" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#get_health_public_insurance" do
    let(:patient_id) { 1 }
    let(:health_public_insurance) { spy("OrcaApi::HealthPublicInsurance") }

    subject { patient_service.get_health_public_insurance(patient_id) }

    before do
      attributes = load_orca_api_response_json("orca12_patientmodv32_01.json").first[1]
      expect(OrcaApi::HealthPublicInsurance).to receive(:new).with(attributes).and_return(health_public_insurance).once

      count = 0
      expect(orca_api).to receive(:call).twice { |path, body: {}|
        case count
        when 0
          expect(path).to eq("/orca12/patientmodv32")

          req = body["patientmodreq"]
          expect(req["Request_Number"]).to eq("01")

          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)
        when 1
          expect(path).to eq("/orca12/patientmodv32")

          req = body["patientmodreq"]
          expect(req["Request_Number"]).to eq("99")

          res01 = load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_01.json").first[1]
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          expect(req["Patient_Information"]).to eq(res01["Patient_Information"])
        end
        count += 1

        load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_#{req["Request_Number"]}.json")
      }
    end

    it { is_expected.to eq(health_public_insurance) }
  end
end
