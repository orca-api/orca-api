# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::Update" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#update" do
    subject { patient_service.update(*args) }

    let(:patient_id) { 1 }
    let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv31_01_modify.json") }

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

          get_response_json
        when 2
          res01 = get_response_json.first[1]
          expect(req["Request_Number"]).to eq("02")
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          # TODO: これ、1の結果に引数をdeep_mergeしたものでないといけない。そうしないとクリアされてしまう。クリアしたければ、全部指定すればOK。
          expect(req["Patient_Information"]).to eq(updated_response_json.first[1]["Patient_Information"])

          updated_response_json
        end
      }
    end

    context "すべての値を指定する" do
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_whole.json") }
      let(:args) {
        [patient_id, updated_response_json.first[1]["Patient_Information"]]
      }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }
    end

    context "一部を指定する" do
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_parts.json") }
      let(:args) {
        patient_information = {
          "BirthDate" => "1975-05-05",
          "Home_Address_Information" => {
            "Address_ZipCode" => "6900055",
          },
          "Home2_Information" => {
            "WholeName" => "",
            "Address_ZipCode" => "",
            "WholeAddress1" => "",
            "WholeAddress2" => nil,
            "PhoneNumber" => nil
          },
          "Death_Flag" => "1",
        }
        [patient_id, patient_information]
      }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }
    end

    context "まったく指定しない" do
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_none.json") }
      let(:args) {
        [patient_id, {}]
      }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }
    end
  end
end
