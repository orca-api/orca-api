# -*- coding: utf-8 -*-

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PatientService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

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
    res_body = prev_response_json.first[1]
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
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response_json("orca12_patientmodv31_99.json")
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
    res_body = prev_response_json.first[1]
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
    res_body = prev_response_json.first[1]
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
    res_body = prev_response_json.first[1]
    expect(req["Request_Number"]).to eq("99")
    expect(req["Karte_Uid"]).to eq(res_body["Karte_Uid"])
    expect(req["Patient_Information"]["Patient_ID"]).to eq(res_body["Patient_Information"]["Patient_ID"])
    expect(req["Orca_Uid"]).to eq(res_body["Orca_Uid"])

    load_orca_api_response_json("orca12_patientmodv32_99.json")
  end

  describe "#create" do
    let(:patient_information) { response_json.first[1]["Patient_Information"] }

    subject { service.create(*args) }

    context "二重登録疑いの患者が存在しない" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_new.json") }
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
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
      its(:duplicated_patient_candidates) { is_expected.to eq([]) }
    end

    context "二重登録疑いの患者が存在する" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_new_abnormal_patient_duplicated.json") }

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
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_json.first[1]["Patient2_Information"]) }
      end

      describe "引数にallow_duplication: trueを指定すると強制的に登録する" do
        let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_02_new_abnormal_patient_duplicated.json") }
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
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_json.first[1]["Patient2_Information"]) }
      end
    end
  end

  describe "#get" do
    let(:patient_id) { 1 }
    let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_modify.json") }

    context "患者情報のみ取得する" do
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
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
      end

      context "異常系" do
        let(:patient_id) { 2000 }
        let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_modify_E10.json") }

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
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
      end
    end

    context "関連情報として患者保険・公費情報も取得する" do
      let(:insurance_response_json) { load_orca_api_response_json("orca12_patientmodv32_01.json") }

      subject { service.get(patient_id, associations: [:health_public_insurance]) }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify", response_json)
            when 2
              expect_orca12_patientmodv31_99(path, body, prev_response_json)
            when 3
              expect_orca12_patientmodv32_01(path, body, patient_id, insurance_response_json)
            when 4
              expect_orca12_patientmodv32_99(path, body, prev_response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }

      describe "health_public_insurance" do
        subject { super().health_public_insurance }

        %w(
          Patient_Information
          HealthInsurance_Information
          PublicInsurance_Information
          HealthInsurance_Combination_Information
        ).each do |name|
          describe "[#{name}]" do
            subject { super()[name] }

            it { is_expected.to eq(insurance_response_json.first[1][name]) }
          end
        end
      end
    end
  end

  describe "#update" do
    subject { service.update(*args) }

    let(:patient_id) { 1 }
    let(:args) {
      [patient_id, patient_information]
    }

    before do
      count = 0
      prev_response_json = nil
      expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
        count += 1
        prev_response_json =
          case count
          when 1
            expect_orca12_patientmodv31_01(path, body, patient_id, nil, "Modify",
                                           "orca12_patientmodv31_01_modify.json")
          when 2
            expect_orca12_patientmodv31_02(path, body, prev_response_json, response_json.first[1]["Patient_Information"],
                                           "Modify", response_json)
          end
        prev_response_json
      }
    end

    context "すべての値を指定する" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_whole.json") }
      let(:patient_information) { response_json.first[1]["Patient_Information"] }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
    end

    context "一部を指定する" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_parts.json") }
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
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
    end

    context "まったく指定しない" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_none.json") }
      let(:patient_information) { {} }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
    end
  end

  describe "#get_health_public_insurance" do
    subject { service.get_health_public_insurance(patient_id) }

    context "正常系" do
      let(:patient_id) { 1 }
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv32_01.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(2) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv32_01(path, body, patient_id, response_json)
            when 2
              expect_orca12_patientmodv32_99(path, body, response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be true }

      describe "health_public_insurance" do
        subject { super().health_public_insurance }

        %w(
          Patient_Information
          HealthInsurance_Information
          PublicInsurance_Information
          HealthInsurance_Combination_Information
        ).each do |name|
          describe "[\"#{name}\"]" do
            subject { super()[name] }

            it { is_expected.to eq(response_json.first[1][name]) }
          end
        end
      end
    end

    context "異常系" do
      let(:patient_id) { 2000 }
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv32_01_E10.json") }

      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(1) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv32_01(path, body, patient_id, response_json)
            end
          prev_response_json
        }
      end

      its("ok?") { is_expected.to be false }
    end
  end

  describe "#update_health_public_insurance" do
    let(:patient_id) { 209 }
    let(:args) {
      [patient_id, health_public_insurance]
    }

    subject { service.update_health_public_insurance(*args) }

    context "正常系" do
      before do
        count = 0
        prev_response_json = nil
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(3) { |path, body:|
          count += 1
          prev_response_json =
            case count
            when 1
              expect_orca12_patientmodv32_01(path, body, patient_id, get_response_json)
            when 2
              expect_orca12_patientmodv32_02(path, body, prev_response_json, health_public_insurance, checked_response_json)
            when 3
              expect_orca12_patientmodv32_03(path, body, prev_response_json, updated_response_json)
            end
          prev_response_json
        }
      end

      shared_examples "結果が正しいこと" do
        its("ok?") { is_expected.to be true }

        describe "health_public_insurance" do
          subject { super().health_public_insurance }

          %w(
            Patient_Information
            HealthInsurance_Information
            PublicInsurance_Information
            HealthInsurance_Combination_Information
          ).each do |name|
            describe "[\"#{name}\"]" do
              subject { super()[name] }

              it { is_expected.to eq(updated_response_json.first[1][name]) }
            end
          end
        end
      end

      context "患者保険・公費を登録する(New)" do
        let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv32_01_new.json") }
        let(:checked_response_json) { load_orca_api_response_json("orca12_patientmodv32_02_new.json") }
        let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv32_03_new.json") }

        let(:health_public_insurance) {
          {
            "HealthInsurance_Information" => {
              "HealthInsurance_Info" => [
                {
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
                },
              ],
            },
            "PublicInsurance_Information" => {
              "PublicInsurance_Info" => [
                {
                  "PublicInsurance_Mode" => "New",
                  "PublicInsurance_Id" => "0",
                  "PublicInsurance_Class" => "968",
                  "PublicInsurance_Name" => "後期該当",
                  "PublicInsurer_Number" => "",
                  "PublicInsuredPerson_Number" => "",
                  "Certificate_IssuedDate" => "2017-01-01",
                  "Certificate_ExpiredDate" => "2017-12-31",
                  "Certificate_CheckDate" => "2017-07-28",
                },
              ],
            },
          }
        }

        include_examples "結果が正しいこと"
      end

      context "患者保険・公費を更新する(Modify)" do
        let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv32_01_modify.json") }
        let(:checked_response_json) { load_orca_api_response_json("orca12_patientmodv32_02_modify.json") }
        let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv32_03_modify.json") }

        let(:health_public_insurance) {
          {
            "HealthInsurance_Information" => {
              "HealthInsurance_Info" => [
                {
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
                },
              ],
            },
            "PublicInsurance_Information" => {
              "PublicInsurance_Info" => [
                {
                  "PublicInsurance_Mode" => "Modify",
                  "PublicInsurance_Id" =>  "0000000001",
                  "PublicInsurance_Class" => "969",
                  "PublicInsurance_Name" => "７５歳特例",
                  "PublicInsurer_Number" => "",
                  "PublicInsuredPerson_Number" => "",
                  "Certificate_IssuedDate" => "2017-01-02",
                  "Certificate_ExpiredDate" => "2017-12-31",
                  "Certificate_CheckDate" => "2017-05-30",
                },
              ],
            },
          }
        }

        include_examples "結果が正しいこと"
      end

      context "患者保険・公費を削除する(Delete)" do
        let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv32_01_delete.json") }
        let(:checked_response_json) { load_orca_api_response_json("orca12_patientmodv32_02_delete.json") }
        let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv32_03_delete.json") }

        let(:health_public_insurance) {
          {
            "HealthInsurance_Information" => {
              "HealthInsurance_Info" => [
                {
                  "InsuranceProvider_Mode" => "Delete",
                  "InsuranceProvider_Id" => "0000000001",
                  "InsuranceProvider_Class" => "039",
                },
              ],
            },
            "PublicInsurance_Information" => {
              "PublicInsurance_Info" => [
                {
                  "PublicInsurance_Mode" => "Delete",
                  "PublicInsurance_Id" => "0000000001",
                  "PublicInsurance_Class" => "969",
                },
              ],
            },
          }
        }

        include_examples "結果が正しいこと"
      end
    end

    context "異常系" do
      let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv32_01_new.json") }
      let(:checked_response_json) { load_orca_api_response_json("orca12_patientmodv32_02_new.json") }
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv32_03_new.json") }
      let(:abort_response_json) { load_orca_api_response_json("orca12_patientmodv32_99.json") }

      let(:health_public_insurance) { {} }

      context "Request_Number=01でエラー: 例)他端末使用中(E90)" do
        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodreq"]

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
          expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodreq"]

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
          expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).exactly(3) { |_, body:|
            req = body["patientmodreq"]

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")

              get_response_json
            when 2
              expect(req["Request_Number"]).to eq("02")

              checked_response_json.first[1]["Api_Result"] = "E50"
              checked_response_json.first[1]["Api_Result_Message"] = "保険・公費にエラーがあります。"
              checked_response_json
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
          expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).exactly(3) { |_, body:|
            req = body["patientmodreq"]

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
          expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).exactly(4) { |_, body:|
            req = body["patientmodreq"]

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

              updated_response_json.first[1]["Api_Result"] = "E80"
              updated_response_json.first[1]["Api_Result_Message"] = "一時データ出力エラーです。強制終了して下さい。"
              updated_response_json
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
          expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).exactly(4) { |_, body:|
            req = body["patientmodreq"]

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
  end
end
