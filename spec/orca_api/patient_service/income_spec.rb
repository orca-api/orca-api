require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::Income, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  def expect_orca12_patientmodv34_01(path, body, patient_id, response_json)
    expect(path).to eq("/orca12/patientmodv34")

    req = body["patientmodv3req4"]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    expect(req["Orca_Uid"]).to eq("")
    expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv34_02(path, body, prev_response_json, params, response_json)
    expect(path).to eq("/orca12/patientmodv34")

    req = body["patientmodv3req4"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Patient_Information"]).to eq(res_body["Patient_Information"])
    expect(req["Income_Information"]).to eq(params["Income_Information"])

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv34_99(path, body, prev_response_json)
    expect(path).to eq("/orca12/patientmodv34")

    req = body["patientmodv3req4"]
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_Information"]["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response_json("orca12_patientmodv34_income_99.json")
  end

  describe "#get" do
    subject { service.get(patient_id) }

    context "正常系" do
      let(:patient_id) { 4 }
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv34_income_01.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv34_01(path, body, patient_id, response_json)
            when 2
              expect_orca12_patientmodv34_99(path, body, response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }

      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
      its(:income_information) { is_expected.to eq(response_json.first[1]["Income_Information"]) }
    end

    context "異常系" do
      let(:patient_id) { 2000 }
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv34_income_01_E10.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv34_01(path, body, patient_id, response_json)
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
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv34_01(path, body, patient_id, get_response_json)
            when 2
              expect_orca12_patientmodv34_02(path, body, prev_response_json, params, updated_response_json)
            end
          prev_response_json
        }
      end

      shared_examples "結果が正しいこと" do
        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }

        attr_name = "Income_Information"
        describe "[#{attr_name.inspect}]" do
          subject { super()[attr_name] }

          it { is_expected.to eq(updated_response_json.first[1][attr_name]) }
        end
      end

      context "更新する" do
        let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_01_modify.json") }
        let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_02_modify.json") }

        let(:params) {
          {
            "Income_Information" => {
              "Income_Mode" => "Modify",
              "Income_Info" => [
                {
                  "Income_StartDate" => "2017-09-01",
                  "Income_ExpiredDate" => "9999-12-31",
                  "Income_Reduction_Date" => "2017-09-30",
                  "Income_Long_Period_Date" => "",
                  "Income_Certificate_Code" => "0",
                  "Income_Boundary_Code" => "1",
                },
              ],
            }
          }
        }

        include_examples "結果が正しいこと"
      end

      context "削除する" do
        let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_01_delete.json") }
        let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_02_delete.json") }

        let(:params) {
          {
            "Income_Information" => {
              "Income_Mode" => "Delete",
            },
          }
        }

        include_examples "結果が正しいこと"
      end
    end

    context "異常系" do
      let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_01_modify.json") }
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_02_modify.json") }
      let(:abort_response_json) { load_orca_api_response_json("orca12_patientmodv34_income_99.json") }

      let(:params) { {} }

      context "Request_Number=01でエラー: 例)他端末使用中(E90)" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv34", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodv3req4"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json.first[1]["Api_Result"] = "E90"
              get_response_json.first[1]["Api_Result_Message"] = "他端末使用中"
              get_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        its("message") { is_expected.to eq("他端末使用中(E90)") }
      end

      context "Request_Number=01で例外発生" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv34", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodv3req4"]

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

      context "Request_Number=02でエラー: 例)低所得者２更新エラー(E61)" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv34", body: instance_of(Hash)).exactly(3) { |_, body:|
            req = body["patientmodv3req4"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json
            when 2
              expect(req["Request_Number"]).to eq("02")

              updated_response_json.first[1]["Api_Result"] = "E61"
              updated_response_json.first[1]["Api_Result_Message"] = "低所得者２更新エラー"
              updated_response_json
            when 3
              expect(req["Request_Number"]).to eq("99")

              abort_response_json
            end
          }
        end

        its("ok?") { is_expected.to be false }
        its("message") { is_expected.to eq("低所得者２更新エラー(E61)") }
      end

      context "Request_Number=02で例外発生" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv34", body: instance_of(Hash)).exactly(3) { |_, body:|
            req = body["patientmodv3req4"]

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
    end
  end
end
