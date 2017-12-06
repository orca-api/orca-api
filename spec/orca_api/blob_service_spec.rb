require "spec_helper"
require_relative "shared_examples"
require "stringio"

RSpec.describe OrcaApi::BlobService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    let(:uid) { "df9c6592-6901-4d63-bf22-392776ede96f" }
    let(:output_io) { StringIO.new }

    context "正常系" do
      it "大容量データを格納したIOを返す" do
        data = load_orca_api_response("blobapi_df9c6592-6901-4d63-bf22-392776ede96f.pdf")

        expect(orca_api).to receive(:call).with("/blobapi/#{uid}", http_method: :get, format: nil, output_io: output_io).once {
          output_io.write(data)
          output_io.rewind
          output_io
        }

        service.get(uid, output_io)

        expect(output_io.read).to eq(data)
      end
    end

    context "異常系" do
      context "404 Not Found" do
        it do
          error = OrcaApi::HttpError.new(double("Net::HTTPNotFound", message: "Not Found", code: "404"))
          expect(orca_api).to receive(:call).
            with("/blobapi/#{uid}", http_method: :get, format: nil, output_io: output_io).once.and_raise(error)

          expect { service.get(uid, output_io) }.to raise_error(OrcaApi::HttpError)
        end
      end
    end
  end
end
