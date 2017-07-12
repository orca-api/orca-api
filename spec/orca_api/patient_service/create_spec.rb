# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService, "::Create" do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#create" do
    subject { patient_service.create(*args) }

    describe "正常系" do
      context "引数にOrcaApi::PatientInformationを指定する" do
        let(:updated_patient) { double("updated_patient") }
        let(:patient) {
          attributes = load_orca_api_response_json("orca12_patientmodv31_01_new.json").first[1]["Patient_Information"]
          OrcaApi::PatientInformation.new(attributes)
        }
        let(:args) { [patient] }

        before do
          body_mock = double("OrcaApi::PatientService::Create::RequestBody")
          expect(OrcaApi::PatientService::Create::RequestBody)
            .to receive(:new).with(karte_uid: orca_api.karte_uid, patient_information: patient).and_return(body_mock).once

          response = load_orca_api_response_json("orca12_patientmodv31_01_new.json")
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: body_mock).and_return(response).once

          attributes = response.first[1]["Patient_Information"]
          expect(patient).to receive(:update).with(attributes).and_return(updated_patient).once
        end

        it { is_expected.to eq(updated_patient) }
      end

      context "引数に患者情報のハッシュを指定する" do
        let(:args) {
          [load_orca_api_response_json("orca12_patientmodv31_01_new.json").first[1]["Patient_Information"]]
        }
        let(:updated_patient) { double("updated_patient") }

        before do
          patient = double("OrcaApi::PatientInformation")
          expect(OrcaApi::PatientInformation).to receive(:new).with(*args).and_return(patient).once
          body = double("OrcaApi::PatientService::Create::RequestBody")
          expect(OrcaApi::PatientService::Create::RequestBody).to receive(:new).and_return(body).once
          result = load_orca_api_response_json("orca12_patientmodv31_01_new.json")
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: body).and_return(result).once
          expect(patient).to receive(:update).with(result.first[1]["Patient_Information"]).and_return(updated_patient).once
        end

        it { is_expected.to eq(updated_patient) }
      end

      context "引数にallow_duplication: trueを指定する" do
        let(:updated_patient) { double("updated_patient") }
        let(:patient) {
          attributes = load_orca_api_response_json("orca12_patientmodv31_01_new.json").first[1]["Patient_Information"]
          OrcaApi::PatientInformation.new(attributes)
        }
        let(:args) { [patient, { allow_duplication: true }] }

        before do
          body_mock = spy("OrcaApi::PatientService::Create::RequestBody")
          expect(OrcaApi::PatientService::Create::RequestBody)
            .to receive(:new).with(karte_uid: orca_api.karte_uid, patient_information: patient).and_return(body_mock).once

          count = 0
          previous_response = nil
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: body_mock).twice { |path, _|
            case count
            when 0
              expect(body_mock).not_to have_received("request_number=")
              expect(body_mock).not_to have_received("orca_uid=")
              expect(body_mock).not_to have_received("select_answer=")

              request_number = "01"
            when 1
              expect(body_mock).to have_received("request_number=").with("02")
              expect(body_mock).to have_received("orca_uid=").with(previous_response.first[1]["Orca_Uid"])
              expect(body_mock).to have_received("select_answer=").with("Ok")

              request_number = "02"
            end
            count += 1

            json_path = "#{path[1..-1].gsub("/", "_")}_#{request_number}_new_abnormal_patient_duplicated.json"
            previous_response = load_orca_api_response_json(json_path)
            previous_response
          }

          json_path = "orca12_patientmodv31_02_new_abnormal_patient_duplicated.json"
          attributes = load_orca_api_response_json(json_path).first[1]["Patient_Information"]
          expect(patient).to receive(:update).with(attributes).and_return(updated_patient).once
        end

        it { is_expected.to eq(updated_patient) }
      end
    end

    describe "異常系" do
      context "同一患者が存在する" do
        let(:patient) { double("OrcaApi::PatientInformation") }
        let(:args) { [patient] }

        before do
          body_mock = double("OrcaApi::PatientService::Create::RequestBody")
          expect(OrcaApi::PatientService::Create::RequestBody)
            .to receive(:new).with(karte_uid: orca_api.karte_uid, patient_information: patient).and_return(body_mock)

          response = load_orca_api_response_json("orca12_patientmodv31_01_new_abnormal_patient_duplicated.json")
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: body_mock).and_return(response).once
        end

        it { expect { subject }.to raise_error(RuntimeError, "PatientDuplicated") }
      end
    end
  end
end
