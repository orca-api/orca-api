require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PatientService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  def expect_orca12_patientmodv31_01(path, body, id, patient, patient_mode, response_json)
    expect(path).to eq("/orca12/patientmodv31")

    req = body["patientmodreq"]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    expect(req["Patient_ID"]).to eq(id.to_s)
    expect(req["Patient_Mode"]).to eq(patient_mode)
    expect(req["Orca_Uid"]).to eq("")
    expect(req["Select_Answer"]).to eq("")
    expect(req["Patient_Information"]).to eq(patient)

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv31_02(path, body, prev_response_json, patient, patient_mode, response_json)
    expect(path).to eq("/orca12/patientmodv31")

    req = body["patientmodreq"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Patient_Mode"]).to eq(patient_mode)
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Select_Answer"]).to eq("Ok")
    expect(req["Patient_Information"]).to eq(patient)

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv31_99(path, body, prev_response_json)
    expect(path).to eq("/orca12/patientmodv31")

    req = body["patientmodreq"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response("orca12_patientmodv31_99.json")
  end

  def expect_orca12_patientmodv32_01(path, body, patient_id, response_json)
    expect(path).to eq("/orca12/patientmodv32")

    req = body["patientmodreq"]
    expect(req["Request_Number"]).to eq("01")
    expect(req["Karte_Uid"]).to eq("karte_uid")
    expect(req["Orca_Uid"]).to eq("")
    expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv32_02(path, body, prev_response_json, health_public_insurance, response_json)
    expect(path).to eq("/orca12/patientmodv32")

    req = body["patientmodreq"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Patient_Information"]).to eq(res_body["Patient_Information"])
    expect(req["HealthInsurance_Information"]).to eq(health_public_insurance["HealthInsurance_Information"])
    expect(req["PublicInsurance_Information"]).to eq(health_public_insurance["PublicInsurance_Information"])

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv32_03(path, body, prev_response_json, response_json)
    expect(path).to eq("/orca12/patientmodv32")

    req = body["patientmodreq"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq(res_body["Response_Number"])
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])
    expect(req["Patient_Information"]).to eq(res_body["Patient_Information"])
    expect(req["HealthInsurance_Information"]).to eq(res_body["HealthInsurance_Information"])
    expect(req["PublicInsurance_Information"]).to eq(res_body["PublicInsurance_Information"])

    return_response_json(response_json)
  end

  def expect_orca12_patientmodv32_99(path, body, prev_response_json)
    expect(path).to eq("/orca12/patientmodv32")

    req = body["patientmodreq"]
    res_body = parse_json(prev_response_json).first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_Information"]["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response("orca12_patientmodv32_99.json")
  end

  describe "#create" do
    let(:patient_information) { response_data.first[1]["Patient_Information"] }

    subject { service.create(*args) }

    context "二重登録疑いの患者が存在しない" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_new.json") }
      let(:args) {
        [patient_information]
      }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv31_01(path, body, "*", patient_information, "New", response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      its(:duplicated_patient_candidates) { is_expected.to eq([]) }
    end

    context "二重登録疑いの患者が存在する" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_new_abnormal_patient_duplicated.json") }

      describe "登録に失敗する" do
        let(:args) {
          [patient_information]
        }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, "*", patient_information, "New", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_data.first[1]["Patient2_Information"]) }
      end

      describe "引数にallow_duplication: trueを指定すると強制的に登録する" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_new_abnormal_patient_duplicated.json") }
        let(:args) {
          [patient_information, { allow_duplication: true }]
        }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, "*", patient_information, "New",
                                               "orca12_patientmodv31_01_new_abnormal_patient_duplicated.json")
              when 2
                expect_orca12_patientmodv31_02(path, body, prev_response_json, patient_information, "New", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_data.first[1]["Patient2_Information"]) }
      end
    end

    context "異常系" do
      let(:args) {
        [patient_information]
      }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv31_01(path, body, "*", patient_information, "New", response_json)
            end
          prev_response_json
        }
      end

      context "必須チェックでエラーが発生する" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_E02.json") }
        let(:patient_information) { {} }

        its("ok?") { is_expected.to be false }
        its(["Orca_Uid"]) { is_expected.to be nil }
      end

      context "世帯主名からコメント２のチェックでエラーが発生した" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_E50.json") }

        its("ok?") { is_expected.to be false }
        %w(
          Patient_Information
          Patient_Message_Information
        ).each do |name|
          its([name]) { is_expected.to eq(response_data.first[1][name]) }
        end
      end

      context "不正な郵便番号を示す警告が発生したが登録処理は完了した" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_W00.json") }

        its("ok?") { is_expected.to be true }
        its(["Api_Result"]) { is_expected.to eq("W00") }
        %w(
          Patient_Information
          Patient_Warning_Information
        ).each do |name|
          its([name]) { is_expected.to eq(response_data.first[1][name]) }
        end
      end
    end
  end

  describe "#get" do
    let(:patient_id) { 1 }
    let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_modify.json") }

    subject { service.get(patient_id) }

    context "正常系" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify", response_json)
            when 2
              expect_orca12_patientmodv31_99(path, body, prev_response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
    end

    context "異常系" do
      let(:patient_id) { 2000 }
      let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_modify_E10.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify", response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be false }
      its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
    end
  end

  describe "#update" do
    subject { service.update(*args) }

    let(:args) {
      [patient_id, patient_information]
    }

    context "正常系" do
      let(:patient_id) { 1 }
      let(:response_json_01) { "orca12_patientmodv31_01_modify.json" }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify", response_json_01)
            when 2
              expect_orca12_patientmodv31_02(path, body, prev_response_json, response_data.first[1]["Patient_Information"],
                                             "Modify", response_json)
            end
          prev_response_json
        }
      end

      context "すべての値を指定する" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_modify_whole.json") }
        let(:patient_information) { response_data.first[1]["Patient_Information"] }

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      end

      context "あらたに自宅情報を指定する" do
        let(:response_json_01) {
          data = parse_json(load_orca_api_response("orca12_patientmodv31_01_modify.json"), false)
          data["patientmodres"]["Patient_Information"].delete("Home_Address_Information")
          data.to_json
        }
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_modify_whole.json") }
        let(:patient_information) { response_data.first[1]["Patient_Information"] }

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      end

      context "一部を指定する" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_modify_parts.json") }
        let(:patient_information) {
          {
            "BirthDate" => "1975-05-05",
            "Home_Address_Information" => {
              "Address_ZipCode" => "6900055",
            },
            "Home2_Information" => {
              "WholeName" => "",
              "Address_ZipCode" => "",
              "WholeAddress1" => "",
              "WholeAddress2" => nil,
              "PhoneNumber" => nil
            },
            "Death_Flag" => "1",
          }
        }

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      end

      context "まったく指定しない" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_modify_none.json") }
        let(:patient_information) { {} }

        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      end
    end

    context "異常系" do
      context "日レセから登録情報を取得するときにエラーが発生する" do
        let(:patient_id) { 9999 }
        let(:response_json_01) { "orca12_patientmodv31_01_E10.json" }
        let(:patient_information) { {} }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify", response_json_01)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end

      context "更新時にエラーが発生する" do
        let(:patient_id) { 1 }
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_modify_E50.json") }
        let(:patient_information) { response_data.first[1]["Patient_Information"] }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(3) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify", "orca12_patientmodv31_01_modify.json")
              when 2
                prev_response_data = parse_json(prev_response_json)
                expect_patient_information = service.send(
                  :deep_merge_for_request_body, prev_response_data.first[1]["Patient_Information"], patient_information
                )
                expect_orca12_patientmodv31_02(
                  path, body, prev_response_json, expect_patient_information, "Modify", response_json
                )
              when 3
                expect_orca12_patientmodv31_99(path, body, prev_response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end
    end
  end

  describe "#destroy" do
    let(:patient_id) { 1 }
    let(:args) { [patient_id] }

    subject { service.destroy(*args) }

    context "正常系" do
      let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_delete_000.json") }

      shared_examples "ok" do
        its("ok?") { is_expected.to be true }
        its(:patient_information) { is_expected.to eq(response_data.first[1]["Patient_Information"]) }
      end

      context "受診のない患者" do
        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(3) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Delete", "orca12_patientmodv31_01_delete.json")
              when 2
                patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                expect_orca12_patientmodv31_02(
                  path, body, prev_response_json, patient, "Delete", "orca12_patientmodv31_02_delete_S20_1.json"
                )
              when 3
                patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                expect_orca12_patientmodv31_02(
                  path, body, prev_response_json, patient, "Delete", response_json
                )
              end
            prev_response_json
          }
        end

        include_examples "ok"
      end

      context "受診のある患者" do
        context "強制削除しない" do
          let(:args) { [patient_id, { force: false }] }
          let(:response_json) { load_orca_api_response("orca12_patientmodv31_02_delete_S20_2.json") }

          before do
            count = 0
            prev_response_json = nil
            locked_result = nil
            expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
              count += 1
              prev_response_json =
                case count
                when 1
                  locked_result = load_orca_api_response("orca12_patientmodv31_01_delete.json")
                  expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Delete", locked_result)
                when 2
                  patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                  expect_orca12_patientmodv31_02(
                    path, body, prev_response_json, patient, "Delete", "orca12_patientmodv31_02_delete_S20_1.json"
                  )
                when 3
                  patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                  expect_orca12_patientmodv31_02(
                    path, body, prev_response_json, patient, "Delete", response_json
                  )
                when 4
                  expect_orca12_patientmodv31_99(path, body, locked_result)
                end
              prev_response_json
            }
          end

          its("ok?") { is_expected.to be false }
        end

        context "強制削除する" do
          let(:args) { [patient_id, { force: true }] }

          before do
            count = 0
            prev_response_json = nil
            expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
              count += 1
              prev_response_json =
                case count
                when 1
                  expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Delete", "orca12_patientmodv31_01_delete.json")
                when 2
                  patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                  expect_orca12_patientmodv31_02(
                    path, body, prev_response_json, patient, "Delete", "orca12_patientmodv31_02_delete_S20_1.json"
                  )
                when 3
                  patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                  expect_orca12_patientmodv31_02(
                    path, body, prev_response_json, patient, "Delete", "orca12_patientmodv31_02_delete_S20_2.json"
                  )
                when 4
                  patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                  expect_orca12_patientmodv31_02(
                    path, body, prev_response_json, patient, "Delete", response_json
                  )
                end
              prev_response_json
            }
          end

          include_examples "ok"
        end
      end
    end

    context "異常系" do
      context "患者番号に該当する患者が存在しません" do
        let(:response_json) { load_orca_api_response("orca12_patientmodv31_01_delete_E10.json") }

        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Delete", response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end

      context "Request_Number=2のときにエラーが発生" do
        before do
          count = 0
          prev_response_json = nil
          expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(3) { |path, body:|
            count += 1
            prev_response_json =
              case count
              when 1
                expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Delete", "orca12_patientmodv31_01_delete.json")
              when 2
                data = parse_json(load_orca_api_response("orca12_patientmodv31_02_delete_S20_1.json"), false)
                data.first[1]["Api_Result"] = "E80"
                data.first[1]["Api_Result_Message"] = "一時データ出力エラーです。強制終了して下さい。"

                patient = parse_json(prev_response_json).first[1]["Patient_Information"]
                expect_orca12_patientmodv31_02(
                  path, body, prev_response_json, patient, "Delete", data.to_json
                )
              when 3
                expect_orca12_patientmodv31_99(path, body, prev_response_json)
              end
            prev_response_json
          }
        end

        its("ok?") { is_expected.to be false }
      end
    end
  end

  %w(
    HealthPublicInsurance
    AccidentInsurance
    Income
    Pension
    Maiden
    SpecialNotes
    Personally
  ).each do |class_name|
    klass = OrcaApi::PatientService.const_get(class_name)
    method_suffix = OrcaApi::OrcaApi.underscore(class_name)

    describe klass.to_s do
      let(:patient_id) { 1 }
      let(:inner_service) { double(klass.name) }
      let(:result) { double("Result") }

      before do
        expect(klass).to receive(:new).with(orca_api).once.and_return(inner_service)
      end

      describe "#get_#{method_suffix}" do
        subject { service.send("get_#{method_suffix}", patient_id) }

        it "#{klass}.new(orca_api).get(patient_id)を呼び出すこと" do
          expect(inner_service).to receive(:get).with(patient_id).once.and_return(result)
          expect(subject).to be(result)
        end
      end

      describe "#update_#{method_suffix}" do
        let(:params) { {} }

        subject { service.send("update_#{method_suffix}", patient_id, params) }

        it "#{klass}.new(orca_api).update(patient_id, params)を呼び出すこと" do
          expect(inner_service).to receive(:update).with(patient_id, params).once.and_return(result)
          expect(subject).to be(result)
        end
      end
    end
  end
end
