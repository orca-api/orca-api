# -*- coding: utf-8 -*-

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::DepartmentService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    let(:response_json) { load_orca_api_response_json("api01rv2_system01lstv2_01.json") }

    before do
      body = {
        "system01_managereq" => {
          "Request_Number" => "01",
          "Base_Date" => base_date,
        }
      }
      expect(orca_api).to receive(:call).with("/api01rv2/system01lstv2", body: body).once.and_return(response_json)
    end

    shared_examples "結果が正しいこと" do
      its("ok?") { is_expected.to be true }
      its(:department_information) { is_expected.to eq(response_json.first[1]["Department_Information"]) }
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
