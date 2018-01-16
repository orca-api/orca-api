# frozen_string_literal: true

require_relative "service"

module OrcaApi
  # ドクターコードを扱うサービスを表現したクラス
  class PhysicianService < Service
    # ドクターコード一覧の取得
    #
    # @param [String] base_date
    #   基準日。YYYY-mm-dd形式。
    #
    # @return [OrcaApi::Result]
    #   https://www.orca.med.or.jp/receipt/tec/api/systemkanri.html#response2
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/systemkanri.html
    def list(base_date = "")
      api_path = "/api01rv2/system01lstv2"
      req_name = "system01_managereq"

      body = {
        req_name => {
          "Request_Number" => "02",
          "Base_Date" => base_date,
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # ユーザー作成
    #
    # @param params [Hash] ユーザー情報
    # @option params [String] User_Id ユーザーID
    # @option params [String] User_Password ユーザーパスワード
    # @option params [String] Full_Name ユーザー氏名
    # @option params [String] Kana_Name ユーザーカナ氏名
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response1
    def create(params)
      api_path = "/orca101/manageusersv2"
      body = {
        "manageusersreq" => {
          "Request_Number" => "02",
          "User_Information" => params.merge("Group_Number" => "1")
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # ユーザー更新
    #
    # @param user_id [String] ユーザーID
    # @param params [Hash] ユーザー情報
    # @option params [String] New_User_Id ユーザーID
    # @option params [String] New_User_Password ユーザーパスワード
    # @option params [String] New_Full_Name ユーザー氏名
    # @option params [String] New_Kana_Name ユーザーカナ氏名
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response2
    def update(user_id, params)
      api_path = "/orca101/manageusersv2"
      body = {
        "manageusersreq" => {
          "Request_Number" => "03",
          "User_Information" => params.merge("User_Id" => user_id)
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # ユーザー削除
    #
    # @param user_id [String] ユーザーID
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response3
    def destroy(user_id)
      api_path = "/orca101/manageusersv2"
      body = {
        "manageusersreq" => {
          "Request_Number" => "04",
          "User_Information" => {
            "User_Id" => user_id
          }
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end
  end
end
