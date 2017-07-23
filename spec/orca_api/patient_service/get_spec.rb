# -*- coding: utf-8 -*-

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::Get" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#get" do
    let(:patient_id) { 1 }
    let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01.json") }

    context "患者情報のみ取得する" do
      subject { patient_service.get(patient_id) }

      before do
        count = 0
        expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).twice { |_, body:|
          req = body["patientmodreq"]

          count += 1
          case count
          when 1
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Patient_Mode"]).to eq("Modify")
            expect(req["Orca_Uid"]).to eq("")

            response_json
          when 2
            expect(req["Request_Number"]).to eq("99")
            res01 = response_json.first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])

            load_orca_api_response_json("orca12_patientmodv31_99.json")
          end
        }
      end

      it { is_expected.to be_kind_of(Hash) }
      it { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
    end
  end
end
