require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PatientService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    subject { service.get(patient_id) }

    context "正常系" do
      let(:patient_id) { "1234" }

      before do
        expect_data = [
          {
            path: "/api01rv2/patientgetv2",
            params: {
              id: patient_id
            },
            result: {
              "patientinfores" => {
                "Api_Result" => "00",
                "Patient_Information" => {
                  "Patient_ID" => patient_id
                }
              }
            }.to_json,
          }
        ]
        expect_orca_api_call(expect_data, binding)
      end

      its("ok?") { is_expected.to be true }
    end

    context "異常系" do
      let(:patient_id) { "" }

      before do
        expect_data = [
          {
            path: "/api01rv2/patientgetv2",
            params: {
              id: ""
            },
            result: {
              "patientinfores" => {
                "Api_Result" => "01",
                "Api_Result_Message" => "患者番号の設定がありません",
              }
            }.to_json,
          }
        ]
        expect_orca_api_call(expect_data, binding)
      end

      its("ok?") { is_expected.to be false }
    end
  end
end
