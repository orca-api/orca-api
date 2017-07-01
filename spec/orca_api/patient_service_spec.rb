# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#get" do
    let(:patient_id) { 1 }

    subject { patient_service.get(patient_id) }

    before do
      count = 0
      expect(orca_api).to receive(:call).twice { |path, body: {}|
        expect(path).to eq("/orca12/patientmodv31")

        req = body["patientmodreq"]

        case req["Request_Number"]
        when "01"
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Patient_ID"]).to eq(patient_id.to_s)
          expect(req["Patient_Mode"]).to eq("Modify")
          expect(req["Orca_Uid"]).to eq("")

          expect(count).to eq(0)
          count += 1
        when "99"
          res01 = load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_01.json")["patientmodres"]

          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])

          expect(count).to eq(1)
          count += 1
        end

        load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_#{req["Request_Number"]}.json")
      }
    end

    it { is_expected.to be_instance_of(OrcaApi::Patient) }
    its(:id) { is_expected.to eq("00001") }
    its(:whole_name) { is_expected.to eq("テスト　カンジャ") }
  end
end
