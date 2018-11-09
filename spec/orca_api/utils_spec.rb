require "spec_helper"

RSpec.describe OrcaApi do
  describe ".underscore" do
    it { expect(OrcaApi.underscore("FooBar")).to eq "foo_bar" }
    it { expect(OrcaApi.underscore("fooBar")).to eq "foo_bar" }
    it { expect(OrcaApi.underscore("FooBar1")).to eq "foo_bar1" }
    it { expect(OrcaApi.underscore("Foo_Bar")).to eq "foo_bar" }
    it { expect(OrcaApi.underscore("Foo_BarBaz")).to eq "foo_bar_baz" }
  end

  describe ".trim_response" do
    it "配列内の空要素オブジェクトを削除すること" do
      result = OrcaApi.trim_response(
        data: [
          { key: 1 }, { key: 2 }, "", [], {}
        ]
      )
      expect(result).to eq(data: [{ key: 1 }, { key: 2 }])
    end

    it "空ではない要素オブジェクトより右のオブジェクトを削除すること" do
      result = OrcaApi.trim_response(
        data: [
          { key: 1 }, { key: 2 }, {}, { key: 3 }, {}
        ]
      )
      expect(result).to eq(data: [{ key: 1 }, { key: 2 }, {}, { key: 3 }])
    end
  end
end
