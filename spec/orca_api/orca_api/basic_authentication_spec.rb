# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::OrcaApi::BasicAuthentication do
  let(:auth) { described_class.new("account", "password") }

  describe "#apply" do
    let(:http) { spy("Net::HTTP") }
    let(:request) { spy("Net::HTTPRequest") }

    subject { auth.apply(http, request) }

    it "BASIC認証に必要な設定を適用できること" do
      subject

      expect(http).not_to have_received("use_ssl=").with(true)
      expect(request).to have_received(:basic_auth).with("account", "password")
    end
  end
end
