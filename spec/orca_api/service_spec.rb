require "spec_helper"

RSpec.describe OrcaApi::Service do
  describe ".reuse_session" do
    let(:service) { service_class.new orca_api }
    let(:orca_api) { OrcaApi::OrcaApi.new "http://example.com" }
    let(:service_class) do
      Class.new(OrcaApi::Service) do
        def call_01
          orca_api.reusing_session?
        end

        def call_02
          orca_api.reusing_session?
        end
      end
    end

    it "セッションの再利用がされないこと" do
      expect {
        service_class.reuse_session :call_02
      }.to_not change { service.call_01 }
    end

    it "セッションの再利用がされること" do
      expect {
        service_class.reuse_session :call_02
      }.to change { service.call_02 }.to(true)
    end

    it "メソッド名を複数指定できること" do
      expect(service_class.reuse_session(:call_01, :call_02).instance_methods).to eq %i[call_01 call_02]
    end
  end
end
