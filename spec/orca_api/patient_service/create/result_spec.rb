# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService::Create::Result do
  subject { described_class.new(raw) }

  context "二重登録疑いの患者が存在しない" do
    let(:raw) { load_orca_api_response_json("orca12_patientmodv31_01_new.json") }

    its(:ok?) { is_expected.to be true }
    its(:patient_information) { is_expected.to eq(raw.first[1]["Patient_Information"]) }
    its(:duplicated_patient_candidates) { [] }
  end

  context "二重登録疑いの患者が存在する" do
    let(:raw) { load_orca_api_response_json("orca12_patientmodv31_01_new_abnormal_patient_duplicated.json") }

    its(:ok?) { is_expected.to be false }
    its(:patient_information) { is_expected.to eq(raw.first[1]["Patient_Information"]) }
    its(:duplicated_patient_candidates) { is_expected.to eq(raw.first[1]["Patient2_Information"]) }
  end
end
