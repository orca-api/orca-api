# -*- coding: utf-8 -*-

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::DiseaseService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  def expect_api01rv2_diseasegetv2(path, params, body, args, response_json)
    expect(path).to eq("/api01rv2/diseasegetv2")
    expect(params).to eq({ "class" => "01" })
    expect(body["disease_inforeq"]).to eq(args)

    return_response_json(response_json)
  end

  describe "#get" do
    let(:args) {
      {
        "Patient_ID" => patient_id.to_s,
        "Base_Date" => "",
      }
    }

    subject { service.get(args) }

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).exactly(1) { |path, body:, params: nil|
        count += 1
        prev_response_json =
          case count
          when 1
            expect_api01rv2_diseasegetv2(path, params, body, args, response_json)
          end
        prev_response_json
      }
    end

    context "正常系" do
      let(:patient_id) { 1 }
      let(:response_json) { load_orca_api_response_json("api01rv2_diseasegetv2.json") }

      its("ok?") { is_expected.to be true }
      its(:disease_infores) { is_expected.to eq(response_json.first[1]["Disease_Infores"]) }
      its(:disease_information) { is_expected.to eq(response_json.first[1]["Disease_Information"]) }
    end

    context "異常系" do
      let(:patient_id) { 9999 }
      let(:response_json) { load_orca_api_response_json("api01rv2_diseasegetv2_10.json") }

      its("ok?") { is_expected.to be false }
    end
  end
end
