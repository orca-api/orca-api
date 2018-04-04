require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::LockService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    context "排他中" do
      it "一覧を取得できる" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "=medicalv3req7" => {
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
              }
            },
            result: "api21_medicalmodv37_00.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.list

        expect(result.ok?).to be true
      end
    end

    context "排他中ではない" do
      it "エラーにはならず、空の一覧を取得できる" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "=medicalv3req7" => {
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
              }
            },
            result: "api21_medicalmodv37_00_E10.json",
          },
        ]

        expect_orca_api_call(expect_data, binding)

        result = service.list

        expect(result.ok?).to be true
        expect(result.lock_information).to eq([])
        expect(result["Lock_Information"]).to eq([])
      end
    end
  end

  describe "#unlock" do
    context "排他中" do
      it "排他制御を解除する" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "=Delete_Information" => {
                  "Delete_Karte_Uid" => "karte_uid",
                  "Delete_Orca_Uid" => "2204825e-c628-4747-8fc2-9e337b32125b",
                },
              }
            },
            result: "api21_medicalmodv37_01_one_S40.json",
          },
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "`prev.response_number`",
                "Karte_Uid" => "`prev.karte_uid`",
                "Orca_Uid" => "`prev.orca_uid`",
                "=Delete_Information" => "`prev.delete_information`",
                "Select_Answer" => "Ok",
              }
            },
            result: "api21_medicalmodv37_01_one.json",
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.unlock("karte_uid", "2204825e-c628-4747-8fc2-9e337b32125b")

        expect(result.ok?).to be true
      end
    end

    context "排他中ではない" do
      it "エラーを返す" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "=Delete_Information" => {
                  "Delete_Karte_Uid" => "karte_uid",
                  "Delete_Orca_Uid" => "7b7c82a9-c703-4f5d-87a0-8312786f2dd5",
                },
              }
            },
            result: "api21_medicalmodv37_01_one_E13.json",
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.unlock("karte_uid", "7b7c82a9-c703-4f5d-87a0-8312786f2dd5")

        expect(result.ok?).to be false
      end
    end
  end

  describe "#unlock_all" do
    context "排他中" do
      it "すべての排他制御を解除する" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
              }
            },
            result: "api21_medicalmodv37_01_all_S40.json",
          },
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "`prev.response_number`",
                "Karte_Uid" => "`prev.karte_uid`",
                "Orca_Uid" => "`prev.orca_uid`",
                "=Delete_Information" => "`prev.delete_information`",
                "Select_Answer" => "Ok",
              }
            },
            result: "api21_medicalmodv37_01_all.json",
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.unlock_all

        expect(result.ok?).to be true
      end
    end

    context "排他中ではない" do
      it "排他制御を解除するための日レセAPIを呼び出す" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => orca_api.karte_uid,
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
              }
            },
            result: "api21_medicalmodv37_01_all_S40_empty.json",
          },
          {
            body: {
              "medicalv3req7" => {
                "Request_Number" => "`prev.response_number`",
                "Karte_Uid" => "`prev.karte_uid`",
                "Orca_Uid" => "`prev.orca_uid`",
                "=Delete_Information" => "`prev.delete_information`",
                "Select_Answer" => "Ok",
              }
            },
            result: "api21_medicalmodv37_01_all.json",
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.unlock_all

        expect(result.ok?).to be true
      end
    end

    context "異常系: Karte_Uidが未設定" do
      let(:orca_api) { double("OrcaApi::Client", karte_uid: "") }

      it "エラーになること" do
        expect_data = [
          {
            path: "/api21/medicalmodv37",
            body: {
              "medicalv3req7" => {
                "Request_Number" => "01",
                "Karte_Uid" => "",
                "=Delete_Information" => {
                  "Delete_Class" => "All",
                },
              }
            },
            result: "api21_medicalmodv37_01_all_E06.json",
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.unlock_all

        expect(result.ok?).to be false
      end
    end
  end
end
