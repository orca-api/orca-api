require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::CareInsurance, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    context "正常系" do
      it "介護保険情報の登録内容を取得できること" do
        expect_data = [
          {
            path: "/orca12/patientmodv36",
            body: {
              "=patientmodv3req6" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv36_get_01.json",
          },
          {
            path: "/orca12/patientmodv36",
            body: {
              "=patientmodv3req6" => {
                "Request_Number" => "99",
                "Karte_Uid" => orca_api.karte_uid,
                "Orca_Uid" => "`prev.orca_uid`",
              }
            },
            result: "orca12_patientmodv36_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(1)

        expect(result.ok?).to be true
      end
    end
  end
end
