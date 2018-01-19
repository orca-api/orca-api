require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::RehabilitationCommentService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    it "一覧を取得できること" do
      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "00",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
            }
          },
          result: "api21_medicalmodv35_list_00.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.list("5")

      expect(result.ok?).to be true
    end
  end

  describe "#get" do
    it "詳細情報を取得できること" do
      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "00",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
              "Perform_Information" => {
                "Medication_Code" => "099830101",
                "Perform_Date" => "2013-01",
                "Insurance_Combination_Number" => "",
              },
            }
          },
          result: "api21_medicalmodv35_get_00.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.get("5", "099830101", "2013-01", "")

      expect(result.ok?).to be true
    end
  end

  describe "#update" do
    it "算定履歴、リハビリコメントを登録できること" do
      args = {
        "Perform_Information": {
          "Perform_Mode": "New",
          "Medication_Code": "099800111",
          "Perform_Date": "2018-01",
          "Perform_Day_Info": [
            {
              "Perform_Day": "01"
            }
          ]
        },
        "Comment_Information": {
          "Comment_Mode": "Modify",
          "Comment_Day_Info": [
            {
              "Comment_Day": "01",
              "Comment_Info": [
                {
                  "Comment": "リハビリコメント"
                }
              ]
            }
          ]
        }
      }

      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "01",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
            }
          },
          result: "api21_medicalmodv35_update__new_01.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__new_02.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.update("5", args)

      expect(result.ok?).to be true
    end

    it "算定履歴、リハビリコメントを更新できること" do
      args = {
        "Perform_Information": {
          "Perform_Mode": "Modify",
          "Medication_Code": "099800111",
          "Perform_Date": "2018-01",
          "Perform_Day_Info": [
            {
              "Perform_Day": "05"
            },
            {
              "Perform_Day": "07"
            }
          ]
        },
        "Comment_Information": {
          "Comment_Mode": "Modify",
          "Comment_Day_Info": [
            {
              "Comment_Day": "05",
              "Comment_Info": [
                {
                  "Comment": "りはびりこめんと５"
                }
              ]
            },
            {
              "Comment_Day": "07",
              "Comment_Info": [
                {
                  "Comment": "りはびりこめんと７"
                }
              ]
            }
          ]
        }
      }

      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "01",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
            }
          },
          result: "api21_medicalmodv35_update__modify_01.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__modify_02.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__modify_03.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.update("5", args)

      expect(result.ok?).to be true
    end

    it "リハビリコメントだけを更新できること" do
      args = {
        "Perform_Information": {
          "Perform_Mode": "",
          "Medication_Code": "099800111",
          "Perform_Date": "2018-01"
        },
        "Comment_Information": {
          "Comment_Mode": "Modify",
          "Comment_Day_Info": [
            {
              "Comment_Day": "05",
              "Comment_Info": [
                {
                  "Comment": "修正したりはびりこめんと５"
                }
              ]
            },
            {
              "Comment_Day": "07",
              "Comment_Info": [
                {
                  "Comment": "修正したりはびりこめんと７"
                }
              ]
            }
          ]
        }
      }

      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "01",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
            }
          },
          result: "api21_medicalmodv35_update__comment_01.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__comment_02.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__comment_03.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.update("5", args)

      expect(result.ok?).to be true
    end

    it "算定履歴、リハビリコメントを削除できること" do
      args = {
        "Perform_Information": {
          "Perform_Mode": "Delete",
          "Medication_Code": "099800111",
          "Perform_Date": "2018-01",
          "Perform_Day_Info": [
            {
              "Perform_Day": "05"
            },
            {
              "Perform_Day": "07"
            }
          ]
        }
      }

      expect_data = [
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => {
              "Request_Number" => "01",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => "5",
            }
          },
          result: "api21_medicalmodv35_update__delete_01.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__delete_02.json",
        },
        {
          path: "/api21/medicalmodv35",
          body: {
            "=medicalv3req5" => args.merge(
              "Request_Number" => "`prev.response_number`",
              "Karte_Uid" => "`prev.karte_uid`",
              "Patient_ID" => "5",
              "Orca_Uid" => "`prev.orca_uid`"
            ),
          },
          result: "api21_medicalmodv35_update__delete_03.json",
        },
      ]

      expect_orca_api_call(expect_data, binding)

      result = service.update("5", args)

      expect(result.ok?).to be true
    end
  end
end
