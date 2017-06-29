# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService do
  let(:orca_api) { double("OrcaApi::OrcaApi") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#get" do
    let(:patient_id) { 1 }

    subject { patient_service.get(patient_id) }

    before do
      expect(orca_api).to receive(:call).twice { |path, body: {}|
        expect(path).to eq("/orca12/patientmodv31")

        req = body["patientmodreq"]

        case req["Request_Number"]
        when "01"
          expect(req["Patient_ID"]).to eq(patient_id.to_s)
          expect(req["Patient_Mode"]).to eq("Modify")
          expect(req["Orca_Uid"]).to eq("")
        when "02"
          fixture_name = "#{path[1..-1].gsub("/", "_")}_01.json"
          fixture_path = File.expand_path(File.join("../../fixtures/orca_api_results", fixture_name), __FILE__)
          res01 = eval(File.read(fixture_path))["patientmodres"]

          expect(req["Patient_ID"]).to eq(res01["Patient_Information"].delete("Patient_ID"))
          expect(req["Patient_Mode"]).to eq("Modify")
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          expect(req["Patient_Information"]).to eq(res01["Patient_Information"])
        end

        fixture_name = "#{path[1..-1].gsub("/", "_")}_#{req["Request_Number"]}.json"
        fixture_path = File.expand_path(File.join("../../fixtures/orca_api_results", fixture_name), __FILE__)
        eval(File.read(fixture_path))
      }
    end

    it { is_expected.to be_instance_of(OrcaApi::Patient) }
    its(:id) { is_expected.to eq("00001") }
    its(:whole_name) { is_expected.to eq("テスト　カンジャ") }
  end
end
