# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService::Result do
  let(:raw) { load_orca_api_response_json("orca12_patientmodv31_01_new.json") }

  subject { described_class.new(raw) }

  its(:patient_information) { is_expected.to eq(raw.first[1]["Patient_Information"]) }
end
