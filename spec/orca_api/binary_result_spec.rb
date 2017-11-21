require "spec_helper"

RSpec.describe OrcaApi::BinaryResult do
  let(:raw) { load_orca_api_response("api01rv2_imagegetv2.zip") }

  subject { described_class.new(raw) }

  its(:raw) { is_expected.to eq(raw) }
  its(:body) { is_expected.to eq(raw) }
  its("ok?") { is_expected.to be true }
  its(:api_result) { is_expected.to eq("0") }
  its(:api_result_message) { is_expected.to eq("正常終了") }
end
