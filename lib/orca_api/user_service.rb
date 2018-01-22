# frozen_string_literal: true

require_relative "service"

module OrcaApi
  # ユーザーを扱うサービスを表現したクラス
  class UserService < Service
    # ユーザー一覧
    #
    # @param [String] base_date
    #   基準日。YYYY-mm-dd形式。
    #
    # @return [OrcaApi::Result]
    #   https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
    def list(base_date = "")
      api_path = "/orca101/manageusersv2"
      body = {
        "manageusersreq" => {
          "Request_Number" => "01",
          "Base_Date" => base_date,
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # ユーザー作成
    #
    # @param params [Hash] ユーザー情報
    # @option params [String] Group_Number 職員区分
    # @option params [String] User_Id ユーザーID
    # @option params [String] User_Password ユーザーパスワード
    # @option params [String] Full_Name ユーザー氏名
    # @option params [String] Kana_Name ユーザーカナ氏名
    #
    # @return [OrcaApi::Result]
    #   https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response1
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
    def create(params)
      api_path = "/orca101/manageusersv2"
      body = {
        "manageusersreq" => {
          "Request_Number" => "02",
          "User_Information" => params
        }
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # ユーザー更新
    #
    # @param user_id [String] ユーザーID
    # @param params [Hash] ユーザー情報
    # @option params [String] New_User_Password ユーザーパスワード
    # @option params [String] New_Full_Name ユーザー氏名
    # @option params [String] New_Kana_Name ユーザーカナ氏名
    #
    # @return [OrcaApi::Result]
    #   https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response2
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
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
    # @return [OrcaApi::Result]
    #   https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#response3
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/userkanri.html#request
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
