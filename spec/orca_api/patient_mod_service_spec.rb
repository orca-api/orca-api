require "spec_helper"
require_relative "shared_examples"

RSpes.describe OrcaApi::PatientModService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#create" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path|
        expect(path).to eq("/orca12/patientmodv2?class=01")
        response_json
      end
    end

    subject { service.create(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv2_01.json") }
      let(:args) do
        {
          Patient_ID: "*",
          WholeName: "千葉　志葉再",
          WholeName_inKana: "カナ　カナ",
          Sex: "2",
          BirthDate: "2000-10-10"
        }

      its("ok?") { is_expected.to be(true) }
    end

    context "異常系" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv2_01_E14.json") }
      let(:args) do
        {
          Patient_ID: "*",
          WholeName: "千葉　志葉a",
          WholeName_inKana: "カナ　カナ",
          Sex: "2",
          BirthDate: "2000-10-10"
        }

      its("ok?") { is_expected.to be(false) }
    end
  end

  describe "#update" do
    before do
      expect(orca_api).to receive(:call).exactly(1) do |path|
        expect(path).to eq("/orca12/patientmodv2?class=02")
        response_json
      end
    end

    subject { service.update(args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv2_02.json") }
      let(:args) do
        {
          Patient_ID: "00019",
          WholeName: "千葉　志葉",
          WholeName_inKana: "カナ　カナ",
          Sex: "2",
          BirthDate: "2000-10-10"
        }

      its("ok?") { is_expected.to be(true) }
    end

    context "異常系" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv2_02_E14.json") }
      let(:args) do
        {
          Patient_ID: "*",
          WholeName: "千葉　志葉a",
          WholeName_inKana: "カナ　カナ",
          Sex: "2",
          BirthDate: "2000-10-10"
        }

      its("ok?") { is_expected.to be(false) }
    end
  end
end
