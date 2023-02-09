require "spec_helper"
require_relative "shared_examples"

RSpes.describe OrcaApi::PatientModService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#create" do
    before do
      
    end
  end
end