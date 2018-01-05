require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::RehabilitationCommentService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    it "一覧を取得できる" do
      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "00",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
            }
          },
          result: "api21_medicalmodv35_00.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.list("5")

      expect(result.ok?).to be true
    end
  end
end
