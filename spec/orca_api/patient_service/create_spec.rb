# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::Create" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#create" do
    subject { patient_service.create(*args) }

    context "二重登録疑いの患者が存在しない" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_new.json") }
      let(:args) {
        [response_json.first[1]["Patient_Information"]]
      }

      before do
        expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).once { |_, body:|
          req = body["patientmodreq"]
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Patient_ID"]).to eq("*")
          expect(req["Patient_Mode"]).to eq("New")
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Select_Answer"]).to eq("")
          expect(req["Patient_Information"]).to eq(args.first)

          response_json
        }
      end

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
      its(:duplicated_patient_candidates) { is_expected.to eq([]) }
    end

    context "二重登録疑いの患者が存在する" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_new_abnormal_patient_duplicated.json") }

      describe "登録に失敗する" do
        let(:args) {
          [response_json.first[1]["Patient_Information"]]
        }

        before do
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq("*")
            expect(req["Patient_Mode"]).to eq("New")
            expect(req["Orca_Uid"]).to eq("")
            expect(req["Select_Answer"]).to eq("")
            expect(req["Patient_Information"]).to eq(args.first)

            response_json
          }
        end

        its("ok?") { is_expected.to be false }
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_json.first[1]["Patient2_Information"]) }
      end

      describe "引数にallow_duplication: trueを指定すると強制的に登録する" do
        let(:args) {
          [response_json.first[1]["Patient_Information"], { allow_duplication: true }]
        }

        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).twice { |_, body:|
            req = body["patientmodreq"]
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq("*")
            expect(req["Patient_Mode"]).to eq("New")
            expect(req["Patient_Information"]).to eq(args.first)

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")
              expect(req["Orca_Uid"]).to eq("")
              expect(req["Select_Answer"]).to eq("")

              response_json
            when 2
              expect(req["Request_Number"]).to eq("02")
              expect(req["Orca_Uid"]).to eq(response_json.first[1]["Orca_Uid"])
              expect(req["Select_Answer"]).to eq("Ok")

              load_orca_api_response_json("orca12_patientmodv31_02_new_abnormal_patient_duplicated.json")
            end
          }
        end

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_json.first[1]["Patient2_Information"]) }
      end
    end
  end
end
