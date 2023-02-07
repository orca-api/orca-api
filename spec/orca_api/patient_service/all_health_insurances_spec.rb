require "spec_helper"
require_relative "../shared_examples"


RSpec.describe OrcaApi::PatientService::AllHealthInsurances, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    before do
      body = {
        "insuranceinfreq" => {
          "Reqest_Number" => "01",
          "Patient_ID" => id,
        }
      }
      expect(orca_api).to receive(:call).with("/api01rv2/patientlst6v2", body: body).once.and_return(response_json)
    end

    subject { service.list }

    context "正常系" do
      let(:response_json) { load_orca_api_response("api01rv2_patientlst6v2.json") }
      let(:id) { "00002" }

      its("ok?") { is_expected.to be(true) }
    end

    context "異常系" do
      let(:response_json) { load_orca_api_response("api01rv2_patientlst6v2_E91.json") }
      let(:id) { "" }

      its("ok?") { is_expected.to be(false) }
    end
  end
end
