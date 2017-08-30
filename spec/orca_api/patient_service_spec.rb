# -*- coding: utf-8 -*-

require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PatientService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#create" do
    subject { service.create(*args) }

    context "二重登録疑いの患者が存在しない" do
      let(:response_json) { load_orca_api_response_json("orca12_patientmodv31_01_new.json") }
      let(:args) {
        [response_json.first[1]["Patient_Information"]]
      }

      before do
        expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).once { |_, body:|
          req = body["patientmodreq"]
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Patient_ID"]).to eq("*")
          expect(req["Patient_Mode"]).to eq("New")
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Select_Answer"]).to eq("")
          expect(req["Patient_Information"]).to eq(args.first)

          response_json
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
          [response_json.first[1]["Patient_Information"]]
        }

        before do
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).once { |_, body:|
            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq("*")
            expect(req["Patient_Mode"]).to eq("New")
            expect(req["Orca_Uid"]).to eq("")
            expect(req["Select_Answer"]).to eq("")
            expect(req["Patient_Information"]).to eq(args.first)

            response_json
          }
        end

        its("ok?") { is_expected.to be false }
        its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
        its(:duplicated_patient_candidates) { is_expected.to eq(response_json.first[1]["Patient2_Information"]) }
      end

      describe "引数にallow_duplication: trueを指定すると強制的に登録する" do
        let(:args) {
          [response_json.first[1]["Patient_Information"], { allow_duplication: true }]
        }

        before do
          count = 0
          expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).twice { |_, body:|
            req = body["patientmodreq"]
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq("*")
            expect(req["Patient_Mode"]).to eq("New")
            expect(req["Patient_Information"]).to eq(args.first)

            count += 1
            case count
            when 1
              expect(req["Request_Number"]).to eq("01")
              expect(req["Orca_Uid"]).to eq("")
              expect(req["Select_Answer"]).to eq("")

              response_json
            when 2
              expect(req["Request_Number"]).to eq("02")
              expect(req["Orca_Uid"]).to eq(response_json.first[1]["Orca_Uid"])
              expect(req["Select_Answer"]).to eq("Ok")

              load_orca_api_response_json("orca12_patientmodv31_02_new_abnormal_patient_duplicated.json")
            end
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

      before do
        count = 0
        expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).twice { |_, body:|
          req = body["patientmodreq"]

          count += 1
          case count
          when 1
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Patient_Mode"]).to eq("Modify")
            expect(req["Orca_Uid"]).to eq("")

            response_json
          when 2
            expect(req["Request_Number"]).to eq("99")
            res01 = response_json.first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])

            load_orca_api_response_json("orca12_patientmodv31_99.json")
          end
        }
      end

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(response_json.first[1]["Patient_Information"]) }
    end

    context "関連情報として患者保険・公費情報も取得する" do
      let(:insurance_response_json) { load_orca_api_response_json("orca12_patientmodv32_01.json") }

      subject { service.get(patient_id, associations: [:health_public_insurance]) }

      before do
        count = 0
        expect(orca_api).to receive(:call).with(instance_of(String), body: instance_of(Hash)).exactly(4) { |path, body:|
          req = body["patientmodreq"]

          count += 1
          case count
          when 1
            expect(path).to eq("/orca12/patientmodv31")

            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Patient_Mode"]).to eq("Modify")
            expect(req["Orca_Uid"]).to eq("")

            response_json
          when 2
            expect(path).to eq("/orca12/patientmodv31")

            expect(req["Request_Number"]).to eq("99")
            res01 = response_json.first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])

            load_orca_api_response_json("orca12_patientmodv31_99.json")
          when 3
            expect(path).to eq("/orca12/patientmodv32")

            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Orca_Uid"]).to eq("")
            expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

            insurance_response_json
          when 4
            expect(path).to eq("/orca12/patientmodv32")

            expect(req["Request_Number"]).to eq("99")
            res01 = insurance_response_json.first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
            expect(req["Patient_Information"]).to eq(res01["Patient_Information"])

            load_orca_api_response_json("orca12_patientmodv32_99.json")
          end
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
    let(:get_response_json) { load_orca_api_response_json("orca12_patientmodv31_01_modify.json") }

    before do
      count = 0
      expect(orca_api).to receive(:call).with("/orca12/patientmodv31", body: instance_of(Hash)).twice { |_, body:|
        req = body["patientmodreq"]
        expect(req["Patient_Mode"]).to eq("Modify")

        count += 1
        case count
        when 1
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Patient_ID"]).to eq(patient_id.to_s)
          expect(req["Orca_Uid"]).to eq("")

          get_response_json
        when 2
          res01 = get_response_json.first[1]
          expect(req["Request_Number"]).to eq("02")
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          expect(req["Patient_Information"]).to eq(updated_response_json.first[1]["Patient_Information"])

          updated_response_json
        end
      }
    end

    context "すべての値を指定する" do
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_whole.json") }
      let(:args) {
        [patient_id, updated_response_json.first[1]["Patient_Information"]]
      }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }
    end

    context "一部を指定する" do
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_parts.json") }
      let(:args) {
        patient_information = {
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
        [patient_id, patient_information]
      }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }
    end

    context "まったく指定しない" do
      let(:updated_response_json) { load_orca_api_response_json("orca12_patientmodv31_02_modify_none.json") }
      let(:args) {
        [patient_id, {}]
      }

      its("ok?") { is_expected.to be true }
      its(:patient_information) { is_expected.to eq(updated_response_json.first[1]["Patient_Information"]) }
    end
  end

  describe "#get_health_public_insurance" do
    let(:patient_id) { 1 }
    let(:response_json) { load_orca_api_response_json("orca12_patientmodv32_01.json") }

    subject { service.get_health_public_insurance(patient_id) }

    before do
      count = 0
      expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).twice { |_, body:|
        req = body["patientmodreq"]

        count += 1
        case count
        when 1
          expect(req["Request_Number"]).to eq("01")
          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

          response_json
        when 2
          expect(req["Request_Number"]).to eq("99")
          res01 = response_json.first[1]
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          expect(req["Patient_Information"]).to eq(res01["Patient_Information"])

          load_orca_api_response_json("orca12_patientmodv32_99.json")
        end
      }
    end

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

  describe "#update_health_public_insurance" do
    let(:patient_id) { 209 }
    let(:args) {
      [patient_id, health_public_insurance]
    }

    subject { service.update_health_public_insurance(*args) }

    context "正常系" do
      before do
        count = 0
        expect(orca_api).to receive(:call).with("/orca12/patientmodv32", body: instance_of(Hash)).exactly(3) { |_, body:|
          req = body["patientmodreq"]

          count += 1
          case count
          when 1
            expect(req["Request_Number"]).to eq("01")
            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Orca_Uid"]).to eq("")
            expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)

            get_response_json
          when 2
            expect(req["Request_Number"]).to eq("02")
            res01 = get_response_json.first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
            expect(req["Patient_Information"]).to eq(res01["Patient_Information"])
            expect(req["HealthInsurance_Information"]).to eq(health_public_insurance["HealthInsurance_Information"])
            expect(req["PublicInsurance_Information"]).to eq(health_public_insurance["PublicInsurance_Information"])

            checked_response_json
          when 3
            expect(req["Request_Number"]).to eq("03")
            res01 = checked_response_json.first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
            expect(req["Patient_Information"]).to eq(res01["Patient_Information"])
            expect(req["HealthInsurance_Information"]).to eq(res01["HealthInsurance_Information"])
            expect(req["PublicInsurance_Information"]).to eq(res01["PublicInsurance_Information"])

            updated_response_json
          end
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
