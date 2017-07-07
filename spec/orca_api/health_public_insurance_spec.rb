# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::HealthPublicInsurance do
  describe ".new" do
    include_examples "ApiStructを日レセAPIのレスポンスやハッシュで初期化できること",
                     OrcaApi::HealthPublicInsurance,
                     load_orca_api_response_json("orca12_patientmodv32_01.json").first[1].freeze
  end
end
