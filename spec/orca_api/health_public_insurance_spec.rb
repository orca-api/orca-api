# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::HealthPublicInsurance do
  describe ".new" do
    TARGET_CLASS = OrcaApi::HealthPublicInsurance
    RESPONSE_JSON = load_orca_api_response_json("orca12_patientmodv32_01.json").first[1].freeze

    subject { OrcaApi::HealthPublicInsurance.new(attributes) }

    describe "日レセAPIのレスポンスから生成する" do
      let(:attributes) { RESPONSE_JSON }

      it { is_expected.to be_instance_of(OrcaApi::HealthPublicInsurance) }
    end
  end
end
