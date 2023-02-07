require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::InsuranceService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#list" do
    let(:response_json) { load_orca_api_response("api01rv2_insuranceinf1v2_01.json") }

    before do
      body = {
        "insuranceinfreq" => {
          "Request_Number" => "01",
          "Base_Date" => base_date,
        }
      }
      expect(orca_api).to receive(:call).with("/api01rv2/insuranceinf1v2", body: body).once.and_return(response_json)
    end

    shared_examples "結果が正しいこと" do
      its("ok?") { is_expected.to be true }
      its(:insurance_information) { is_expected.to eq(response_data.first[1]["Insurance_Information"]) }
    end

    context "引数を省略する" do
      let(:base_date) { "" }

      subject { service.list }

      include_examples "結果が正しいこと"
    end

    context "base_date引数を指定する" do
      let(:base_date) { "2017-07-25" }

      subject { service.list(base_date) }

      include_examples "結果が正しいこと"
    end
  end
end
