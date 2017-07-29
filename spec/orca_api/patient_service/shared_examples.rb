# coding: utf-8

require "spec_helper"
require_relative "../shared_examples"

RSpec.shared_examples "patient_service_with_orca_api_mock", patient_service_with_orca_api_mock: true do
  include_examples "orca_api_mock"
  let(:patient_service) { OrcaApi::PatientService.new(orca_api) }
end
