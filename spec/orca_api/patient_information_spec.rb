# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientInformation do
  include_examples "ApiStructを日レセAPIのレスポンスやハッシュで初期化できること",
                   OrcaApi::PatientInformation,
                   load_orca_api_response_json("orca12_patientmodv31_01.json").first[1]["Patient_Information"].freeze
end
