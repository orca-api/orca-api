require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::AccidentInsurance, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  def expect_orca12_patientmodv33_01(path, body, patient_id, response_json)
    expect(path).to eq("/orca12/patientmodv33")

    req = body["patientmodv3req3"]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    expect(req["Orca_Uid"]).to eq("")
    expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv33_02(path, body, prev_response_json, params, response_json)
    expect(path).to eq("/orca12/patientmodv33")

    req = body["patientmodv3req3"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Patient_Information"]).to eq(res_body["Patient_Information"])
    expect(req["Accident_Insurance_Information"]).to eq(params["Accident_Insurance_Information"])

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv33_03(path, body, prev_response_json, response_json)
    expect(path).to eq("/orca12/patientmodv33")

    req = body["patientmodv3req3"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Patient_Information"]).to eq(res_body["Patient_Information"])
    expect(req["Accident_Insurance_Information"]).to eq(res_body["Accident_Insurance_Information"])

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv33_99(path, body, prev_response_json)
    expect(path).to eq("/orca12/patientmodv33")

    req = body["patientmodv3req3"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_Information"]["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response("orca12_patientmodv33_99.json")
  end

  describe "#get" do
    subject { service.get(patient_id) }

    context "正常系" do
      let(:patient_id) { 4 }
      let(:response_json) { load_orca_api_response("orca12_patientmodv33_01.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv33_01(path, body, patient_id, response_json)
            when 2
              expect_orca12_patientmodv33_99(path, body, response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }

      its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      its(:accident_insurance_information) { is_expected.to eq(response_data.first[1]["Accident_Insurance_Information"]) }
    end

    context "異常系" do
      let(:patient_id) { 2000 }
      let(:response_json) { load_orca_api_response("orca12_patientmodv33_01_E10.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv33_01(path, body, patient_id, response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be false }
    end
  end

  describe "#update" do
    let(:patient_id) { 209 }
    let(:args) {
      [patient_id, params]
    }

    subject { service.update(*args) }

    context "正常系" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(3) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv33_01(path, body, patient_id, get_response_json)
            when 2
              expect_orca12_patientmodv33_02(path, body, prev_response_json, params, checked_response_json)
            when 3
              expect_orca12_patientmodv33_03(path, body, prev_response_json, updated_response_json)
            end
          prev_response_json
        }
      end

      shared_examples "結果が正しいこと" do
        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(parse_json(updated_response_json).first[1]["Patient_Information"]) }

        describe '["Accident_Insurance_Information"]' do
          subject { super()["Accident_Insurance_Information"] }

          it { is_expected.to eq(parse_json(updated_response_json).first[1]["Accident_Insurance_Information"]) }
        end
      end

      context "患者労災・自賠責保険を登録する(New)" do
        let(:get_response_json) { load_orca_api_response("orca12_patientmodv33_01_new.json") }
        let(:checked_response_json) { load_orca_api_response("orca12_patientmodv33_02_new.json") }
        let(:updated_response_json) { load_orca_api_response("orca12_patientmodv33_03_new.json") }

        let(:params) {
          {
            "Accident_Insurance_Information" => {
              "Accident_Insurance_Info" => [
                {
                  "Accident_Mode" => "New",
                  "InsuranceProvider_Id" => "0",
                  "PublicInsurance_Id" => "0",
                  "InsuranceProvider_Class" => "971",
                  "InsuranceProvider_WholeName" => "労災保険",
                  "Accident_Insurance" => "1",
                  "Accident_Insurance_WholeName" => "短期給付", # 労災保険名称/50
                  "Disease_Location" => "肘",
                  "Disease_Date" => "2017-09-29",
                  "Accident_StartDate" => "2017-09-29",
                  "Accident_Insurance_Number" => "12345678901", # 労働保険番号/14/※５
                  "Accident_Class" => "1",
                  "Labor_Station_Code" => "12349",
                  "Accident_Continuous" => "1",
                  "Outcome_Reason" => "3",
                  "Limbs_Exception" => "0",
                  "Liability_Office_Information" => {
                    "L_WholeName" => "松江共同",
                    "Prefecture_Information" => {
                      "P_WholeName" => "島根",
                      "P_Class" => "4",
                      "P_Class_Name" => "県"
                    },
                    "City_Information" => {
                      "C_WholeName" => "松江",
                      "C_Class" => "2",
                      "C_Class_Name" => "市"
                    },
                    "Accident_Base_Month" => "2017-09",
                    "Accident_Receipt_Count" => "001",
                  }
                }
              ],
            },
          }
        }

        include_examples "結果が正しいこと"
      end

      context "患者労災・自賠責保険を更新する(Modify)" do
        let(:get_response_json) { load_orca_api_response("orca12_patientmodv33_01_modify.json") }
        let(:checked_response_json) { load_orca_api_response("orca12_patientmodv33_02_modify.json") }
        let(:updated_response_json) { load_orca_api_response("orca12_patientmodv33_03_modify.json") }

        let(:params) {
          {
            "Accident_Insurance_Information" => {
              "Accident_Insurance_Info" => [
                {
                  "Accident_Mode" => "Modify",
                  "InsuranceProvider_Id" => "9",
                  "PublicInsurance_Id" => "0",
                  "InsuranceProvider_Class" => "971",
                  "InsuranceProvider_WholeName" => "労災保険",
                  "Accident_Insurance" => "1",
                  "Accident_Insurance_WholeName" => "短期給付", # 労災保険名称/50
                  "Disease_Location" => "肩腰",
                  "Disease_Date" => "2017-09-29",
                  "Accident_StartDate" => "2017-09-29",
                  "Accident_Insurance_Number" => "12345678901", # 労働保険番号/14/※５
                  "Accident_Class" => "1",
                  "Labor_Station_Code" => "12349",
                  "Accident_Continuous" => "1",
                  "Outcome_Reason" => "3",
                  "Limbs_Exception" => "0",
                  "Liability_Office_Information" => {
                    "L_WholeName" => "松江共同",
                    "Prefecture_Information" => {
                      "P_WholeName" => "島根",
                      "P_Class" => "4",
                      "P_Class_Name" => "県"
                    },
                    "City_Information" => {
                      "C_WholeName" => "松江",
                      "C_Class" => "2",
                      "C_Class_Name" => "市"
                    },
                    "Accident_Base_Month" => "2017-09",
                    "Accident_Receipt_Count" => "001",
                  }
                }
              ],
            },
          }
        }

        include_examples "結果が正しいこと"
      end

      context "患者労災・自賠責保険を削除する(Delete)" do
        let(:get_response_json) { load_orca_api_response("orca12_patientmodv33_01_delete.json") }
        let(:checked_response_json) { load_orca_api_response("orca12_patientmodv33_02_delete.json") }
        let(:updated_response_json) { load_orca_api_response("orca12_patientmodv33_03_delete.json") }

        let(:params) {
          {
            "Accident_Insurance_Information" => {
              "Accident_Insurance_Info" => [
                {
                  "Accident_Mode" => "Delete",
                  "InsuranceProvider_Id" => "9",
                  "PublicInsurance_Id" => "0",
                  "InsuranceProvider_Class" => "971",
                  "InsuranceProvider_WholeName" => "労災保険",
                  "Accident_Insurance" => "1",
                  "Accident_Insurance_WholeName" => "短期給付", # 労災保険名称/50
                  "Disease_Location" => "肘",
                  "Disease_Date" => "2017-09-29",
                  "Accident_StartDate" => "2017-09-29",
                  "Accident_Insurance_Number" => "12345678901", # 労働保険番号/14/※５
                  "Accident_Class" => "1",
                  "Labor_Station_Code" => "12349",
                  "Accident_Continuous" => "1",
                  "Outcome_Reason" => "3",
                  "Limbs_Exception" => "0",
                  "Liability_Office_Information" => {
                    "L_WholeName" => "松江共同",
                    "Prefecture_Information" => {
                      "P_WholeName" => "島根",
                      "P_Class" => "4",
                      "P_Class_Name" => "県"
                    },
                    "City_Information" => {
                      "C_WholeName" => "松江",
                      "C_Class" => "2",
                      "C_Class_Name" => "市"
                    },
                    "Accident_Base_Month" => "2017-09",
                    "Accident_Receipt_Count" => "001",
                  }
                }
              ],
            },
          }
        }

        include_examples "結果が正しいこと"
      end
    end

    context "異常系" do
      let(:get_response_json) { load_orca_api_response("orca12_patientmodv33_01_new.json") }
      let(:checked_response_json) { load_orca_api_response("orca12_patientmodv33_02_new.json") }
      let(:updated_response_json) { load_orca_api_response("orca12_patientmodv33_03_new.json") }
      let(:abort_response_json) { load_orca_api_response("orca12_patientmodv33_99.json") }

      let(:params) { {} }

      context "Request_Number=01でエラー: 例)他端末使用中(E90)" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv33", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodv3req3"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              data = parse_json(get_response_json, false)
              data.first[1]["Api_Result"] = "E90"
              data.first[1]["Api_Result_Message"] = "他端末使用中"
              data.to_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        its("message") { is_expected.to eq("他端末使用中(E90)") }
      end

      context "Request_Number=01で例外発生" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv33", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodv3req3"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              raise "exception"
            end
          }
        end

        it { expect { subject }.to raise_error(RuntimeError, "exception") }
      end

      context "Request_Number=02でエラー: 例)保険・公費にエラーがあります。(E50)" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv33", body: instance_of(Hash)).exactly(3) { |_, body:|
            req = body["patientmodv3req3"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json
            when 2
              expect(req["Request_Number"]).to eq("02")

              data = parse_json(checked_response_json, false)
              data.first[1]["Api_Result"] = "E50"
              data.first[1]["Api_Result_Message"] = "保険・公費にエラーがあります。"
              data.to_json
            when 3
              expect(req["Request_Number"]).to eq("99")

              abort_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        its("message") { is_expected.to eq("保険・公費にエラーがあります。(E50)") }
      end

      context "Request_Number=02で例外発生" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv33", body: instance_of(Hash)).exactly(3) { |_, body:|
            req = body["patientmodv3req3"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json
            when 2
              expect(req["Request_Number"]).to eq("02")

              raise "exception"
            when 3
              expect(req["Request_Number"]).to eq("99")

              abort_response_json
            end
          }
        end

        it { expect { subject }.to raise_error(RuntimeError, "exception") }
      end

      context "Request_Number=03でエラー: 例)一時データ出力エラーです。強制終了して下さい。(E80)" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv33", body: instance_of(Hash)).exactly(4) { |_, body:|
            req = body["patientmodv3req3"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json
            when 2
              expect(req["Request_Number"]).to eq("02")

              checked_response_json
            when 3
              expect(req["Request_Number"]).to eq("03")

              data = parse_json(updated_response_json, false)
              data.first[1]["Api_Result"] = "E80"
              data.first[1]["Api_Result_Message"] = "一時データ出力エラーです。強制終了して下さい。"
              data.to_json
            when 4
              expect(req["Request_Number"]).to eq("99")

              abort_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        its("message") { is_expected.to eq("一時データ出力エラーです。強制終了して下さい。(E80)") }
      end

      context "Request_Number=03で例外発生" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv33", body: instance_of(Hash)).exactly(4) { |_, body:|
            req = body["patientmodv3req3"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json
            when 2
              expect(req["Request_Number"]).to eq("02")

              checked_response_json
            when 3
              expect(req["Request_Number"]).to eq("03")

              raise "exception"
            when 4
              expect(req["Request_Number"]).to eq("99")

              abort_response_json
            end
          }
        end

        it { expect { subject }.to raise_error(RuntimeError, "exception") }
      end
    end

    context "選択項目" do
      let(:base_params) {
        {
          "Accident_Insurance_Information" => {
            "Accident_Insurance_Info" => [
              {
                "Accident_Mode" => "Delete",
                "InsuranceProvider_Id" => "9",
                "PublicInsurance_Id" => "0",
                "InsuranceProvider_Class" => "971",
                "InsuranceProvider_WholeName" => "労災保険",
                "Accident_Insurance" => "1",
                "Accident_Insurance_WholeName" => "短期給付", # 労災保険名称/50
                "Disease_Location" => "肩腰",
                "Disease_Date" => "2017-09-29",
                "Accident_StartDate" => "2017-09-29",
                "Accident_Insurance_Number" => "12345678901", # 労働保険番号/14/※５
                "Accident_Class" => "1",
                "Labor_Station_Code" => "12349",
                "Accident_Continuous" => "1",
                "Outcome_Reason" => "3",
                "Limbs_Exception" => "0",
                "Liability_Office_Information" => {
                  "L_WholeName" => "松江共同",
                  "Prefecture_Information" => {
                    "P_WholeName" => "島根",
                    "P_Class" => "4",
                    "P_Class_Name" => "県"
                  },
                  "City_Information" => {
                    "C_WholeName" => "松江",
                    "C_Class" => "2",
                    "C_Class_Name" => "市"
                  },
                  "Accident_Base_Month" => "2017-09",
                  "Accident_Receipt_Count" => "001",
                }
              }
            ],
          }
        }
      }

      context "選択項目を選択済み" do
        let(:get_response_json) { load_orca_api_response("orca12_patientmodv33_01_select_answer.json") }
        let(:checked_response_json) { load_orca_api_response("orca12_patientmodv33_02_select_answer.json") }
        let(:updated_response_json) { load_orca_api_response("orca12_patientmodv33_03_select_answer.json") }
        let(:answer_response_json) { load_orca_api_response("orca12_patientmodv33_03_answer.json") }
        let(:params) {
          base_params.merge({
            "Patient_Select_Information" => [{
              "Patient_Select" => "K910",
              "Patient_Select_Message" => "保険組合せ更新で期間外の診療が発生します。更新内容を確認して下さい。",
              "Select_Answer" => "Ok"
            }]
          })
        }
        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv33_01(path, body, patient_id, get_response_json)
              when 2
                expect_orca12_patientmodv33_02(path, body, prev_response_json, params, checked_response_json)
              when 3
                expect_orca12_patientmodv33_03(path, body, prev_response_json, updated_response_json)
              when 4
                expect_orca12_patientmodv33_03(path, body, prev_response_json, answer_response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(parse_json(updated_response_json).first[1]["Patient_Information"]) }

        describe '["Accident_Insurance_Information"]' do
          subject { super()["Accident_Insurance_Information"] }

          it { is_expected.to eq(parse_json(updated_response_json).first[1]["Accident_Insurance_Information"]) }
        end
      end

      context "選択項目が未選択" do
        let(:get_response_json) { load_orca_api_response("orca12_patientmodv33_01_select_answer.json") }
        let(:checked_response_json) { load_orca_api_response("orca12_patientmodv33_02_select_answer.json") }
        let(:updated_response_json) { load_orca_api_response("orca12_patientmodv33_03_select_answer.json") }
        let(:unlock_response_json) { load_orca_api_response("orca12_patientmodv33_99.json") }
        let(:params) { base_params }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv33_01(path, body, patient_id, get_response_json)
              when 2
                expect_orca12_patientmodv33_02(path, body, prev_response_json, params, checked_response_json)
              when 3
                expect_orca12_patientmodv33_03(path, body, prev_response_json, updated_response_json)
              when 4
                expect_orca12_patientmodv33_99(path, body, unlock_response_json)
              end
            prev_response_json
          }
        end
        its("ok?") { is_expected.to be false }
        its("message") { is_expected.to eq("選択項目が未指定です。") }
      end
    end

  end
end
