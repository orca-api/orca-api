require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::HealthInsurance, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    context "正常系" do
      it "患者保険情報の登録内容を取得できること" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_health_01.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
              }
            },
            result: "orca12_patientmodv32_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(1)

        expect(result.ok?).to be true
      end
    end

    context "異常系" do
      it "患者番号に該当する患者が存在しない場合、ロック解除を行わないこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "999999",
                }
              }
            },
            result: "orca12_patientmodv32_health_01_E10.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(999999)

        expect(result.ok?).to be false
      end
    end
  end

  describe "#update" do
    context "正常系" do
      it "患者保険情報を更新できること" do
        args = {
          "HealthInsurance_Info" => [
            {
              "InsuranceProvider_Mode": "Modify",
              "InsuranceProvider_Id": "2",
              "InsuranceProvider_Class": "009",
              "InsuranceProvider_Number": "",
              "InsuranceProvider_WholeName": "協会",
              "HealthInsuredPerson_Symbol": "２",
              "HealthInsuredPerson_Number": "３４５６７",
              "HealthInsuredPerson_Continuation": "",
              "HealthInsuredPerson_Assistance": "",
              "RelationToInsuredPerson": "2",
              "HealthInsuredPerson_WholeName": "テスト　太郎",
              "Certificate_StartDate": "2012-10-01",
              "Certificate_ExpiredDate": "2018-02-28",
              "Certificate_GetDate": "2012-10-01",
              "Certificate_CheckDate": "2018-02-01",
              "Rate_Class": ""
            }
          ]
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_health_01.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => '`prev.response_number`',
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => args,
              },
            },
            result: "orca12_patientmodv32_health_02.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => '`prev.response_number`',
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev['HealthInsurance_Information']`",
              },
            },
            result: "orca12_patientmodv32_health_03.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.update(1, args)

        expect(result.ok?).to be true
      end

      it "患者保険情報を削除できること" do
        args = {
          "HealthInsurance_Info" => [
            {
              "InsuranceProvider_Mode" => "Delete",
              "InsuranceProvider_Id" => "7",
              "InsuranceProvider_Class" => "009"
            }
          ]
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_health_01.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => '`prev.response_number`',
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => args,
              },
            },
            result: "orca12_patientmodv32_health_delete_02.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => '`prev.response_number`',
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev['HealthInsurance_Information']`",
              },
            },
            result: "orca12_patientmodv32_health_delete_03.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.update(1, args)

        expect(result.ok?).to be true
      end
    end

    context "異常系" do
      it "患者番号に該当する患者が存在しない場合、ロック解除を行わないこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "999999",
                }
              }
            },
            result: "orca12_patientmodv32_health_01_E10.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.update(999999, {})

        expect(result.ok?).to be false
      end

      it "保険有効開始日＜有効終了日の場合、エラーが発生してロックを解除すること" do
        args = {
          "HealthInsurance_Info" => [
            {
              "InsuranceProvider_Mode": "Modify",
              "InsuranceProvider_Id": "2",
              "InsuranceProvider_Class": "009",
              "InsuranceProvider_Number": "",
              "InsuranceProvider_WholeName": "協会",
              "HealthInsuredPerson_Symbol": "２",
              "HealthInsuredPerson_Number": "３４５６７",
              "HealthInsuredPerson_Continuation": "",
              "HealthInsuredPerson_Assistance": "",
              "RelationToInsuredPerson": "2",
              "HealthInsuredPerson_WholeName": "テスト　太郎",
              "Certificate_StartDate": "2018-01-15",
              "Certificate_ExpiredDate": "2012-10-01",
              "Certificate_GetDate": "2012-10-01",
              "Certificate_CheckDate": "2018-01-01",
              "Rate_Class": ""
            }
          ]
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_health_01.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => '`prev.response_number`',
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => args,
              },
            },
            result: "orca12_patientmodv32_health_02_E50.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
              }
            },
            result: "orca12_patientmodv32_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.update(1, args)

        expect(result.ok?).to be false
      end
    end
  end
end
