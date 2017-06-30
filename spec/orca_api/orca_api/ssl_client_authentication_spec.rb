# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::OrcaApi::SslClientAuthentication do
  let(:auth) { described_class.new("ca_file", "cert_path", "key_path") }

  describe "#cert" do
    subject { auth.cert }

    before do
      expect(File).to receive(:read).with("cert_path").and_return("cert_file").once.ordered
      expect(OpenSSL::X509::Certificate).to receive(:new).with("cert_file").and_return("cert").once.ordered
    end

    it { is_expected.to eq("cert") }
  end

  describe "#key" do
    subject { auth.key }

    before do
      expect(File).to receive(:read).with("key_path").and_return("key_file").once.ordered
      expect(OpenSSL::PKey::RSA).to receive(:new).with("key_file").and_return("key").once.ordered
    end

    it { is_expected.to eq("key") }
  end

  describe "#apply" do
    let(:http) { spy("Net::HTTP") }
    let(:request) { spy("Net::HTTPRequest") }

    subject { auth.apply(http, request) }

    before do
      allow(auth).to receive(:cert).and_return("cert")
      allow(auth).to receive(:key).and_return("key")
    end

    it "SSLクライアント認証に必要な設定を適用できること" do
      subject

      expect(http).to have_received("use_ssl=").with(true).once
      expect(http).to have_received("ca_file=").with("ca_file").once
      expect(http).to have_received("cert=").with("cert").once
      expect(http).to have_received("key=").with("key").once
      expect(http).to have_received("verify_mode=").with(OpenSSL::SSL::VERIFY_PEER).once
    end
  end
end
