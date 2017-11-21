require "spec_helper"

RSpec.describe OrcaApi::FormResult do
  let(:response_json) { load_orca_api_response("api01rv2_formdatagetv2.json") }

  subject { described_class.new(response_json) }

  its(:raw) { is_expected.to eq(response_json) }
  its(:body) { is_expected.to eq(parse_json(response_json, false)) }
  its("ok?") { is_expected.to be true }

  describe "#[]" do
    it "JSONのキーを指定して、値を取得できること" do
      json = parse_json(response_json, false)
      %w(
        Information_Date
        Information_Time
        Api_Result
        Api_Result_Message
        Form_ID
        Form_Name
        Print_Date
        Print_Time
        Patient
        Forms
      ).each do |name|
        expect(subject[name]).to eq(json[name])
      end
    end
  end
end
