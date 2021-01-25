require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::HealthPublicInsurance, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#get" do
    subject { service.get(patient_id) }

    context "正常系" do
      it "works" do
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
            result: "orca12_patientmodv32_01.json",
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
      it "works" do
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
            result: "orca12_patientmodv32_01_E10.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.get(1)

        expect(result.ok?).to be false
      end
    end
  end

  describe "#fetch" do
    subject { service.fetch(patient_id) }

    context "正常系" do
      it "works" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "00",
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_01.json",
          }
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.fetch(1)

        expect(result.ok?).to be true
      end

      it "保険・公費情報のチェックをする" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "00",
                "Base_Date" => "2021-01-01",
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_00_E00.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.fetch(1, "2021-01-01")

        expect(result.ok?).to be false
      end
    end

    context "異常系" do
      it "works" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "00",
                "Patient_Information" => {
                  "Patient_ID" => "1",
                }
              }
            },
            result: "orca12_patientmodv32_01_E10.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.fetch(1)

        expect(result.ok?).to be false
      end
    end
  end

  describe "#update" do
    context "正常系" do
      it "患者保険・公費を登録する(New)" do
        health_insurance_info = {
          "InsuranceProvider_Mode" => "New",
          "InsuranceProvider_Id" => "0",
          "InsuranceProvider_Class" => "039",
          "InsuranceProvider_Number" => "39322011",
          "InsuranceProvider_WholeName" => "後期高齢者",
          "HealthInsuredPerson_Number" => "１２３４５６",
          "HealthInsuredPerson_Assistance" => "1",
          "HealthInsuredPerson_Assistance_Name" => "１割",
          "RelationToInsuredPerson" => "1",
          "HealthInsuredPerson_WholeName" => "東京　太郎",
          "Certificate_StartDate" => "2017-01-01",
          "Certificate_ExpiredDate" => "2017-12-31",
          "Certificate_GetDate" => "2017-01-03",
          "Certificate_CheckDate" => "2017-07-26",
        }
        public_insurance_info = {
          "PublicInsurance_Mode" => "New",
          "PublicInsurance_Id" => "0",
          "PublicInsurance_Class" => "968",
          "PublicInsurance_Name" => "後期該当",
          "PublicInsurer_Number" => "",
          "PublicInsuredPerson_Number" => "",
          "Certificate_IssuedDate" => "2017-01-01",
          "Certificate_ExpiredDate" => "2017-12-31",
          "Certificate_CheckDate" => "2017-07-28",
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_new.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => {
                  "HealthInsurance_Info" => [health_insurance_info],
                },
                "PublicInsurance_Information" => {
                  "PublicInsurance_Info" => [public_insurance_info],
                },
              }
            },
            result: "orca12_patientmodv32_02_new.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`",
                "PublicInsurance_Information" => "`prev.public_insurance_information`",
              }
            },
            result: "orca12_patientmodv32_03_new.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "HealthInsurance_Information" => {
            "HealthInsurance_Info" => [health_insurance_info],
          },
          "PublicInsurance_Information" => {
            "PublicInsurance_Info" => [public_insurance_info],
          },
        }
        result = service.update(209, args)

        expect(result.ok?).to be true
      end

      it "患者保険だけを登録する(New)" do
        health_insurance_info = {
          "InsuranceProvider_Mode" => "New",
          "InsuranceProvider_Id" => "0",
          "InsuranceProvider_Class" => "039",
          "InsuranceProvider_Number" => "39322011",
          "InsuranceProvider_WholeName" => "後期高齢者",
          "HealthInsuredPerson_Number" => "１２３４５６",
          "HealthInsuredPerson_Assistance" => "1",
          "HealthInsuredPerson_Assistance_Name" => "１割",
          "RelationToInsuredPerson" => "1",
          "HealthInsuredPerson_WholeName" => "東京　太郎",
          "Certificate_StartDate" => "2017-01-01",
          "Certificate_ExpiredDate" => "2017-12-31",
          "Certificate_GetDate" => "2017-01-03",
          "Certificate_CheckDate" => "2017-07-26",
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_new.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => {
                  "HealthInsurance_Info" => [health_insurance_info],
                },
              }
            },
            result: "orca12_patientmodv32_02_new_only_health_insurance.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`",
              }
            },
            result: "orca12_patientmodv32_03_new_only_health_insurance.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "HealthInsurance_Information" => {
            "HealthInsurance_Info" => [health_insurance_info],
          },
        }
        result = service.update(209, args)

        expect(result.ok?).to be true
      end

      it "患者公費だけを登録する(New)" do
        public_insurance_info = {
          "PublicInsurance_Mode" => "Modify",
          "PublicInsurance_Id" => "0000000001",
          "PublicInsurance_Class" => "969",
          "PublicInsurance_Name" => "７５歳特例",
          "PublicInsurer_Number" => "",
          "PublicInsuredPerson_Number" => "",
          "Certificate_IssuedDate" => "2017-01-02",
          "Certificate_ExpiredDate" => "2017-12-31",
          "Certificate_CheckDate" => "2017-05-30",
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_new.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => {
                  "PublicInsurance_Info" => [public_insurance_info],
                },
              }
            },
            result: "orca12_patientmodv32_02_new_only_public_insurance.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "PublicInsurance_Information" => "`prev.public_insurance_information`",
              }
            },
            result: "orca12_patientmodv32_03_new_only_public_insurance.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "PublicInsurance_Information" => {
            "PublicInsurance_Info" => [public_insurance_info],
          },
        }
        result = service.update(209, args)

        expect(result.ok?).to be true
      end

      it "患者保険・公費を更新する(Modify)" do
        health_insurance_info = {
          "InsuranceProvider_Mode" => "Modify",
          "InsuranceProvider_Id" => "0000000001",
          "InsuranceProvider_Class" => "039",
          "InsuranceProvider_Number" => "39322011",
          "InsuranceProvider_WholeName" => "後期高齢者",
          "HealthInsuredPerson_Number" => "６５４３２１",
          "HealthInsuredPerson_Assistance" => "1",
          "HealthInsuredPerson_Assistance_Name" => "１割",
          "RelationToInsuredPerson" => "1",
          "HealthInsuredPerson_WholeName" => "東京　太郎",
          "Certificate_StartDate" => "2017-01-01",
          "Certificate_ExpiredDate" => "2017-12-31",
          "Certificate_GetDate" => "2017-01-03",
          "Certificate_CheckDate" => "2017-07-26",
        }
        public_insurance_info = {
          "PublicInsurance_Mode" => "Modify",
          "PublicInsurance_Id" => "0000000001",
          "PublicInsurance_Class" => "969",
          "PublicInsurance_Name" => "７５歳特例",
          "PublicInsurer_Number" => "",
          "PublicInsuredPerson_Number" => "",
          "Certificate_IssuedDate" => "2017-01-02",
          "Certificate_ExpiredDate" => "2017-12-31",
          "Certificate_CheckDate" => "2017-05-30",
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_modify.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => {
                  "HealthInsurance_Info" => [health_insurance_info]
                },
                "PublicInsurance_Information" => {
                  "PublicInsurance_Info" => [public_insurance_info]
                },
              }
            },
            result: "orca12_patientmodv32_02_modify.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`",
                "PublicInsurance_Information" => "`prev.public_insurance_information`",
              }
            },
            result: "orca12_patientmodv32_03_modify.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "HealthInsurance_Information" => {
            "HealthInsurance_Info" => [
              health_insurance_info
            ],
          },
          "PublicInsurance_Information" => {
            "PublicInsurance_Info" => [
              public_insurance_info
            ],
          },
        }
        result = service.update(209, args)

        expect(result.ok?).to be true
      end

      it "患者保険・公費を削除する(Delete)" do
        health_insurance_info = {
          "InsuranceProvider_Mode" => "Delete",
          "InsuranceProvider_Id" => "0000000001",
          "InsuranceProvider_Class" => "039",
        }
        public_insurance_info = {
          "PublicInsurance_Mode" => "Delete",
          "PublicInsurance_Id" => "0000000001",
          "PublicInsurance_Class" => "969",
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_delete.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => {
                  "HealthInsurance_Info" => [health_insurance_info],
                },
                "PublicInsurance_Information" => {
                  "PublicInsurance_Info" => [public_insurance_info],
                },
              }
            },
            result: "orca12_patientmodv32_02_delete.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`",
                "PublicInsurance_Information" => "`prev.public_insurance_information`",
              }
            },
            result: "orca12_patientmodv32_03_delete.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "HealthInsurance_Information" => {
            "HealthInsurance_Info" => [health_insurance_info],
          },
          "PublicInsurance_Information" => {
            "PublicInsurance_Info" => [public_insurance_info],
          },
        }
        result = service.update(209, args)

        expect(result.ok?).to be true
      end
    end

    context "異常系" do
      it "Request_Number=01でエラーが返却されたらロック解除を行わないこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_E10.json",
          }
        ]

        expect_orca_api_call(expect_data, binding)

        args = {}
        result = service.update(209, args)

        expect(result.ok?).to be false
      end

      it "Request_Number=02でエラーが返却されたらロック解除を行うこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_new.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
              }
            },
            result: "orca12_patientmodv32_02_new.json",
            enhancer: lambda { |json|
              json["patientmodv3res2"]["Api_Result"] = "E50"
              json["patientmodv3res2"]["Api_Result_Message"] = "保険・公費にエラーがあります。"
              json
            }
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`"
              }
            },
            result: "orca12_patientmodv32_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {}
        result = service.update(209, args)

        expect(result.ok?).to be false
        expect(result.message).to eq "保険・公費にエラーがあります。(E50)"
      end

      it "Request_Number=03でエラーが返却されたらロック解除を行うこと" do
        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "209",
                }
              }
            },
            result: "orca12_patientmodv32_01_new.json",
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
              }
            },
            result: "orca12_patientmodv32_02_new.json"
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`",
                "PublicInsurance_Information" => "`prev.public_insurance_information`",
              }
            },
            result: "orca12_patientmodv32_03_new.json",
            enhancer: lambda { |json|
              json["patientmodv3res2"]["Api_Result"] = "E80"
              json["patientmodv3res2"]["Api_Result_Message"] = "一時データ出力エラーです。強制終了して下さい。"
              json
            }
          },
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`"
              }
            },
            result: "orca12_patientmodv32_99.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        args = {}
        result = service.update(209, args)

        expect(result.ok?).to be false
        expect(result.message).to eq "一時データ出力エラーです。強制終了して下さい。(E80)"
      end
    end

    context "選択項目" do
      it "選択項目を選択済み" do
        health_insurance_info = {
          "InsuranceProvider_Mode" => "Delete",
          "InsuranceProvider_Id" => "0000000001",
          "InsuranceProvider_Class" => "002",
          "InsuranceProvider_WholeName" => "船員",
          "RelationToInsuredPerson" => "1",
          "HealthInsuredPerson_WholeName" => "テスト　二朗",
          "Certificate_StartDate" => "2018-04-01",
          "Certificate_ExpiredDate" => "2018-04-01",
          "Certificate_CheckDate" => "2018-04-26"
        }
        patient_select_information = {
          "Patient_Select" => "K910",
          "Patient_Select_Message" => "保険組合せ更新で期間外の診療が発生します。更新内容を確認して下さい。",
          "Select_Answer" => "Ok"
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "00002",
                }
              }
            },
            result: "orca12_patientmodv32_01_select_answer.json",
          },

          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => {
                  "HealthInsurance_Info" => [health_insurance_info],
                }
              }
            },
            result: "orca12_patientmodv32_02_select_answer.json",
          },

          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`"
              }
            },
            result: "orca12_patientmodv32_03_select_answer.json"
          },

          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`",
                "Select_Answer" => "Ok"
              }
            },
            result: "orca12_patientmodv32_03_answer.json"
          }
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "HealthInsurance_Information" => {
            "HealthInsurance_Info" => [health_insurance_info],
          },
          "Patient_Select_Information" => [patient_select_information]
        }
        result = service.update("00002", args)

        expect(result.ok?).to be true
        expect(result.message).to eq "登録処理終了。警告メッセージがあります。確認して下さい。(W00)"
      end

      it "選択項目が未選択" do
        health_insurance_info = {
          "InsuranceProvider_Mode" => "Delete",
          "InsuranceProvider_Id" => "0000000001",
          "InsuranceProvider_Class" => "002",
          "InsuranceProvider_WholeName" => "船員",
          "RelationToInsuredPerson" => "1",
          "HealthInsuredPerson_WholeName" => "テスト　二朗",
          "Certificate_StartDate" => "2018-04-01",
          "Certificate_ExpiredDate" => "2018-04-01",
          "Certificate_CheckDate" => "2018-04-26"
        }

        expect_data = [
          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "Patient_Information" => {
                  "Patient_ID" => "00002",
                }
              }
            },
            result: "orca12_patientmodv32_01_select_answer.json",
          },

          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "02",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => {
                  "HealthInsurance_Info" => [health_insurance_info],
                }
              }
            },
            result: "orca12_patientmodv32_02_select_answer.json",
          },

          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "03",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "`prev.orca_uid`",
                "Patient_Information" => "`prev.patient_information`",
                "HealthInsurance_Information" => "`prev.health_insurance_information`"
              }
            },
            result: "orca12_patientmodv32_03_select_answer.json"
          },

          {
            path: "/orca12/patientmodv32",
            body: {
              "=patientmodv3req2" => {
                "Request_Number" => "99",
                "Karte_Uid" => '`prev.karte_uid`',
                "Orca_Uid" => "53a2caa3-627f-434b-8d8e-c24bcff6b96e",
                "Patient_Information" => "`prev.patient_information`",
              }
            },
            result: "orca12_patientmodv32_99.json"
          }
        ]

        expect_orca_api_call(expect_data, binding)

        args = {
          "HealthInsurance_Information" => {
            "HealthInsurance_Info" => [health_insurance_info],
          }
        }
        result = service.update("00002", args)

        expect(result.ok?).to be false
        expect(result.message).to eq "選択項目が未指定です。"
      end
    end
  end
end
