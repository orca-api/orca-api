require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::FindService, orca_api_mock: true do
  describe OrcaApi::FindService::FindResult do
    describe "doing?" do
      it "Api_ResultがE1040であればtrueを返すこと" do
        result = described_class.new(load_orca_api_response("orca13_findv3_02_E1040.json"))
        expect(result.doing?).to be true
      end

      it "Api_ResultがE1040でなければfalseを返すこと" do
        result = described_class.new(load_orca_api_response("orca13_findv3_02.json"))
        expect(result.doing?).to be false
      end
    end
  end

  let(:service) { described_class.new(orca_api) }

  describe "#settings" do
    it "検索指示のリクエストを行う際の設定値を返すこと" do
      expect_data = [
        {
          path: "/orca13/findinfv3",
          body: {
            "=findinfv3req" => {
              "Request_Number" => "01",
              "Base_Date" => "2018-03-27",
            },
          },
          response: "orca13_findinfv3_01.json",
        },
      ]
      expect_orca_api_call(expect_data, binding)

      result = service.settings("2018-03-27")

      expect(result.ok?).to be true
    end

    it "base_dateを省略できること" do
      expect_data = [
        {
          path: "/orca13/findinfv3",
          body: {
            "=findinfv3req" => {
              "Request_Number" => "01",
              "Base_Date" => "",
            },
          },
          response: "orca13_findinfv3_01.json",
        },
      ]
      expect_orca_api_call(expect_data, binding)

      result = service.settings

      expect(result.ok?).to be true
    end
  end
end
