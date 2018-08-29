# frozen_string_literal: true

require_relative "service"

module OrcaApi
  # 統計実施処理を扱うクラス
  #
  # @example
  #   service = orca_api.new_statistics_form_service
  #   list_result = service.list mode: :daily
  #
  #   list_result.statistics_processing_list_information
  #   # => 処理一覧
  #
  #   # 取得したい統計情報のパラメータなどを設定する
  #   list_result.statistics_processing_list_information = []
  #
  #   create_result = service.create list_result
  #
  #   create_result.err_processing_information
  #   # => エラー一覧
  #   create_result.data_id_information
  #   # => 大容量APIで取得するデータID
  #
  #   # 作成処理が終わるまで #created で問い合わせる
  #   loop do
  #     created_result = service.created create_result
  #     break unless created_result.doing?
  #     sleep 1
  #   end
  #
  #   # 作成処理が終わったら大容量APIで帳票を取得する
  #   blob_result = orca_api.new_blob_service.get reate_result.data_id_information[0]["Print_Id"]
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/22145
  class StatisticsFormService < Service
    MODES = {
      daily: "Daily",
      monthly: "Monthly"
    }.freeze
    private_constant :MODES

    # 情報取得のレスポンスクラス
    class ListResult < ::OrcaApi::Result
      # @return [Array<Hash>] 処理一覧
      def statistics_processing_list_information
        Array(body["Statistics_Processing_List_Information"])
      end

      # @param value [Array<Hash>] 処理一覧
      def statistics_processing_list_information=(value)
        body["Statistics_Processing_List_Information"] = Array(value)
      end
    end

    # 処理実施のレスポンスクラス
    class CreateResult < ::OrcaApi::Result
      # @return [Array<Hash>] 処理一覧
      def statistics_processing_list_information
        Array(body["Statistics_Processing_List_Information"])
      end

      # @return [Array<Hash>] エラー処理一覧
      def err_processing_information
        Array(body["Err_Processing_Information"])
      end

      # @return [Array<Hash>] ID一覧
      def data_id_information
        Array(body["Data_Id_Information"])
      end
    end

    # 処理確認のレスポンスクラス
    class CreatedResult < ::OrcaApi::Result
      # @return [Array<Hash>] 処理一覧
      def statistics_processing_list_information
        Array(body["Statistics_Processing_List_Information"])
      end

      # 処理中かどうか
      #
      # @return [Boolean] 処理中であればtrue、そうでなければfalse。
      def doing?
        api_result == "E70"
      end
    end

    # @param mode [Symbol]
    #   指示区分
    #   - :daily
    #   - :monthly
    # @return [ListResult] 情報取得のレスポンスクラス
    def list(mode:)
      raise ArgumentError unless MODES.key? mode
      ListResult.new(
        orca_api.call(
          "/orca51/statisticsformv3",
          body: {
            statistics_formv3req: {
              "Request_Number" => "00",
              "Karte_Uid" => orca_api.karte_uid,
              "Statistics_Mode" => MODES[mode]
            }
          }
        )
      )
    end

    # @param list_result [ListResult]
    # @return [CreateResult] 処理実施のレスポンスクラス
    def create(list_result)
      statistics_processing_list_information = extract_statistics_processing_list_information list_result
      CreateResult.new(
        orca_api.call(
          "/orca51/statisticsformv3",
          body: {
            statistics_formv3req: {
              "Request_Number" => "01",
              "Karte_Uid" => list_result.karte_uid,
              "Statistics_Mode" => list_result.statistics_mode,
              "Statistics_Processing_List_Information" => statistics_processing_list_information
            }
          }
        )
      )
    end

    # @param create_result [CreateResult]
    # @return [CreatedResult] 処理確認のレスポンスクラス
    def created(create_result)
      statistics_processing_list_information = extract_statistics_processing_list_information create_result
      CreatedResult.new(
        orca_api.call(
          "/orca51/statisticsformv3",
          body: {
            statistics_formv3req: {
              "Request_Number" => "02",
              "Karte_Uid" => create_result.karte_uid,
              "Orca_Uid" => create_result.orca_uid,
              "Statistics_Mode" => create_result.statistics_mode,
              "Statistics_Processing_List_Information" => statistics_processing_list_information
            }
          }
        )
      )
    end

    private

    def extract_statistics_processing_list_information(result)
      result.statistics_processing_list_information.map do |spl|
        statistics_parameter_information = extract_statistics_parameter_information spl["Statistics_Parameter_Information"]
        {
          "Statistics_Program_No" => spl["Statistics_Program_No"],
          "Statistics_Program_Name" => spl["Statistics_Program_Name"],
          "Statistics_Program_Label" => spl["Statistics_Program_Label"],
          "Statistics_Parameter_Information" => statistics_parameter_information
        }
      end
    end

    def extract_statistics_parameter_information(array)
      Array(array).map do |spi|
        {
          "Statistics_Parm_No" => spi["Statistics_Parm_No"],
          "Statistics_Parm_Class" => spi["Statistics_Parm_Class"],
          "Statistics_Parm_Label" => spi["Statistics_Parm_Label"],
          "Statistics_Parm_Required_Item" => spi["Statistics_Parm_Required_Item"],
          "Statistics_Parm_Value" => spi["Statistics_Parm_Value"]
        }
      end
    end
  end
end
