require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::StatisticsFormService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    it "API呼び出しが正しいこと" do
      expect_orca_api_call(
        [
          {
            path: "/orca51/statisticsformv3",
            body: {
              statistics_formv3req: {
                "Request_Number" => "00",
                "Karte_Uid" => orca_api.karte_uid,
                "Statistics_Mode" => "Daily"
              }
            },
            response: {
              "statistics_formv3res" => {
                "Api_Result" => "000",
                "Api_Result_Message" => "情報取得終了",
                "Statistics_Mode" => "Daily",
                "Statistics_Processing_List_Information" => []
              }
            }.to_json
          }
        ],
        binding
      )

      result = service.list mode: :daily
      expect(result.ok?).to be true
    end

    it "指定できないモードであれば例外が発生すること" do
      expect {
        service.list mode: :yearly
      }.to raise_error ArgumentError
    end
  end

  describe "#create" do
    it "API呼び出しが正しいこと" do
      list_result = OrcaApi::StatisticsFormService::ListResult.new(
        {
          "statistics_formv3res" => {
            "Karte_Uid" => "2bb20edb-2b25-4093-bb61-7542708d362a",
            "Statistics_Mode" => "Daily",
            "Statistics_Processing_List_Information" => [
              {
                "Statistics_Program_No" => "001",
                "Statistics_Program_Name" => "ORCBD002",
                "Statistics_Program_Label" => "日計表",
                "Statistics_Parameter_Information" => [
                  {
                    "Statistics_Parm_No" => "01",
                    "Statistics_Parm_Class" => "YMD",
                    "Statistics_Parm_Label" => "伝票発行日",
                    "Statistics_Parm_Required_Item" => "True",
                    "Statistics_Parm_Value" => "YYYY-MM-DD"
                  }
                ]
              }
            ]
          }
        }.to_json
      )

      expect_orca_api_call(
        [
          {
            path: "/orca51/statisticsformv3",
            body: {
              statistics_formv3req: {
                "Request_Number" => "01",
                "Karte_Uid" => "2bb20edb-2b25-4093-bb61-7542708d362a",
                "Statistics_Mode" => "Daily",
                "Statistics_Processing_List_Information" => [
                  {
                    "Statistics_Program_No" => "001",
                    "Statistics_Program_Name" => "ORCBD002",
                    "Statistics_Program_Label" => "日計表",
                    "Statistics_Parameter_Information" => [
                      {
                        "Statistics_Parm_No" => "01",
                        "Statistics_Parm_Class" => "YMD",
                        "Statistics_Parm_Label" => "伝票発行日",
                        "Statistics_Parm_Required_Item" => "True",
                        "Statistics_Parm_Value" => "YYYY-MM-DD"
                      }
                    ]
                  }
                ]
              }
            },
            response: {
              "statistics_formv3res" => {
                "Api_Result" => "000",
                "Api_Result_Message" => "情報取得終了",
                "Statistics_Mode" => "Daily",
                "Statistics_Processing_List_Information" => [
                  {
                    "Statistics_Program_No" => "001",
                    "Statistics_Program_Name" => "ORCBD002",
                    "Statistics_Program_Label" => "日計表",
                  }
                ]
              }
            }.to_json
          }
        ],
        binding
      )

      result = service.create list_result
      expect(result.ok?).to be true
    end
  end

  describe "#created" do
    let(:create_result) do
      OrcaApi::StatisticsFormService::ListResult.new(
        {
          "statistics_formv3res" => {
            "Karte_Uid" => "2bb20edb-2b25-4093-bb61-7542708d362a",
            "Orca_Uid" => "7b853f24-6bac-483e-a8bb-8eb6685e913f",
            "Statistics_Mode" => "Daily",
            "Statistics_Processing_List_Information" => [
              {
                "Statistics_Program_No" => "001",
                "Statistics_Program_Name" => "ORCBD002",
                "Statistics_Program_Label" => "日計表",
              }
            ]
          }
        }.to_json
      )
    end

    it "API呼び出しが正しいこと" do
      expect_orca_api_call(
        [
          {
            path: "/orca51/statisticsformv3",
            body: {
              statistics_formv3req: {
                "Request_Number" => "02",
                "Karte_Uid" => "2bb20edb-2b25-4093-bb61-7542708d362a",
                "Orca_Uid" => "7b853f24-6bac-483e-a8bb-8eb6685e913f",
                "Statistics_Mode" => "Daily",
                "Statistics_Processing_List_Information" => [
                  {
                    "Statistics_Program_No" => "001",
                    "Statistics_Program_Name" => "ORCBD002",
                    "Statistics_Program_Label" => "日計表"
                  }
                ]
              }
            },
            response: {
              "statistics_formv3res" => {
                "Request_Number" => "02",
                "Response_Number" => "01",
                "Api_Result" => "E70",
                "Api_Result_Message" => "処理中です【日計表（伝票発行日）】",
              }
            }.to_json
          }
        ],
        binding
      )

      result = service.created create_result
      expect(result.ok?).to be false
    end
  end

  describe OrcaApi::StatisticsFormService::ListResult do
    let(:list_result) do
      described_class.new(
        {
          "statistics_formv3res" => {
            "Karte_Uid" => "2bb20edb-2b25-4093-bb61-7542708d362a",
            "Statistics_Mode" => "Daily",
            "Statistics_Processing_List_Information" => [
              {
                "Statistics_Program_No" => "001",
                "Statistics_Program_Name" => "ORCBD002",
                "Statistics_Program_Label" => "日計表",
                "Statistics_Parameter_Information" => nil
              }
            ]
          }
        }.to_json
      )
    end

    describe "#statistics_processing_list_information" do
      it "Arrayでラップした値を返すこと" do
        expect(list_result.statistics_processing_list_information).to eq [{ "Statistics_Program_No" => "001",
                                                                            "Statistics_Program_Name" => "ORCBD002",
                                                                            "Statistics_Program_Label" => "日計表",
                                                                            "Statistics_Parameter_Information" => nil }]
      end
    end

    describe "#statistics_processing_list_information=" do
      it "Arrayでラップした値を保持すること" do
        list_result.statistics_processing_list_information = nil
        expect(list_result.statistics_processing_list_information).to eq Array(nil)
      end
    end
  end

  describe OrcaApi::StatisticsFormService::CreateResult do
    let(:create_result) do
      described_class.new(
        {
          "statistics_formv3res" => {
            "Karte_Uid" => "2bb20edb-2b25-4093-bb61-7542708d362a",
            "Orca_Uid" => "7b853f24-6bac-483e-a8bb-8eb6685e913f",
            "Statistics_Mode" => "Daily",
            "Statistics_Processing_List_Information" => [
              {
                "Statistics_Program_No" => "001",
                "Statistics_Program_Name" => "ORCBD002",
                "Statistics_Program_Label" => "日計表",
              }
            ],
            "Data_Id_Information" => [
              { "Data_Id" => "foo" }
            ]
          }
        }.to_json
      )
    end

    describe "#err_processing_information" do
      it "Arrayでラップした値を返すこと" do
        expect(create_result.err_processing_information).to eq []
      end
    end

    describe "#data_id_information" do
      it "Arrayでラップした値を返すこと" do
        expect(create_result.data_id_information).to eq [{ "Data_Id" => "foo" }]
      end
    end
  end

  describe OrcaApi::StatisticsFormService::CreatedResult do
    describe "#doing?" do
      it "Api_ResultがE70ならばtrueを返すこと" do
        created_result = described_class.new(
          {
            "statistics_formv3res" => {
              "Api_Result" => "E70"
            }
          }.to_json
        )

        expect(created_result.doing?).to eq true
      end

      it "それ以外の場合はfalseを返すこと" do
        created_result = described_class.new(
          {
            "statistics_formv3res" => {
              "Api_Result" => "00"
            }
          }.to_json
        )

        expect(created_result.doing?).to eq false
      end
    end
  end
end
