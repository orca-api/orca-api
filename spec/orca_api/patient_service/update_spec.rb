# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::Update" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#update" do
    subject { patient_service.update(*args) }

    let(:patient_id) { 1 }
    let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_modify.json") }
    let(:args) {
      [patient_id, response_json.first[1]["Patient_Information"]]
    }

    before do
      count = 0
      expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).twice { |_, body:|
        req = body["patientmodreq"]
        expect(req["Patient_Mode"]).to eq("Modify")

        count += 1
        case count
        when 1
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Patient_ID"]).to eq(patient_id.to_s)
          expect(req["Orca_Uid"]).to eq("")

          response_json
        when 2
          res01 = response_json.first[1]
          expect(req["Request_Number"]).to eq("02")
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          # TODO: これ、1の結果に引数をdeep_mergeしたものでないといけない。そうしないとクリアされてしまう。クリアしたければ、全部指定すればOK。
          expect(req["Patient_Information"]).to eq(args[1])

          load_orca_api_response_json("orca12_patientmodv31_02_modify.json")
        end
      }
    end

    its("ok?") { is_expected.to be true }
    its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
  end
end
