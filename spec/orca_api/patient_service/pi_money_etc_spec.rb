require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::PiMoneyEtc, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    context "正常系" do
      it "公費負担額一覧を取得できること" do
        expect_data = [
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "5",
                }
              }
            },
            result: "orca12_patientmodv35_etc_01.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => {
                  "PublicInsurance_Id" => "1",
                },
              }
            },
            result: "orca12_patientmodv35_etc_02.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "04",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => {
                  "PublicInsurance_Id" => '`prev.pi_money_information["Sel_PublicInsurance_Id"]`',
                },
                "Pi_Money_Sel_Information" => {
                  "Pi_Money_Sel_Number" => "2",
                  "Pi_Money_Sel_StartDate" => "2012-05-01",
                },
              }
            },
            result: "orca12_patientmodv35_etc_04.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
              }
            },
            result: "orca12_patientmodv35_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(5, 1, 2, "2012-05-01")

        expect(result.ok?).to be true
      end
    end

    context "異常系" do
      it "患者番号に該当する患者が存在しない場合、ロック解除を行わないこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "999999",
                }
              }
            },
            result: "orca12_patientmodv35_01_E10.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(999999, 1, 2, "2012-05-01")

        expect(result.ok?).to be false
      end

      it "公費IDに該当する公費が存在しない場合、ロック解除を行うこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "3",
                }
              }
            },
            result: "orca12_patientmodv35_01.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => {
                  "PublicInsurance_Id" => "5",
                },
              }
            },
            result: "orca12_patientmodv35_02_E32.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
              }
            },
            result: "orca12_patientmodv35_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(3, 5, 2, "2012-05-01")

        expect(result.ok?).to be false
      end

      it "対象の公費負担額が存在しない場合、ロック解除を行うこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "5",
                }
              }
            },
            result: "orca12_patientmodv35_etc_01.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => {
                  "PublicInsurance_Id" => "1",
                },
              }
            },
            result: "orca12_patientmodv35_etc_02.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "04",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => {
                  "PublicInsurance_Id" => '`prev.pi_money_information["Sel_PublicInsurance_Id"]`',
                },
                "Pi_Money_Sel_Information" => {
                  "Pi_Money_Sel_Number" => "2",
                  "Pi_Money_Sel_StartDate" => "2012-06-01",
                },
              }
            },
            result: "orca12_patientmodv35_etc_04_E43.json",
          },
          {
            path: "/orca12/patientmodv35",
            body: {
              "=patientmodv3req5" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
              }
            },
            result: "orca12_patientmodv35_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(5, 1, 2, "2012-06-01")

        expect(result.ok?).to be false
      end
    end
  end
end
