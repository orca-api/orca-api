require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::ImageService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    let(:image_id) { "1#ff9d1763-47ae-4563-bff2-24f68a7a370d" }
    let(:response) { load_orca_api_response("api01rv2_imagegetv2.zip") }

    subject { service.get(image_id) }

    before do
      body = {
        "imagegetv2req" => {
          "Image_ID" => image_id
        }
      }
      expect(orca_api).to receive(:call).with("/api01rv2/imagegetv2", body: body).once.and_return(response)
    end

    its("ok?") { is_expected.to be true }
    its(:raw) { is_expected.to eq(response) }
  end
end
