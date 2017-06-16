require "spec_helper"

RSpec.describe OrcaApi::OrcaApi do
  let(:orca_api_options) { {} }
  let(:orca_api) { OrcaApi::OrcaApi.new(orca_api_options) }

  describe "#call" do
    let(:args) { [] }
    subject { orca_api.call(*args) }

    it { is_expected.to be_nil }
  end
end
