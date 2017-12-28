require_relative "service"

module OrcaApi
  # 排他制御解除を行うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/20796
  class LockService < Service
    # 排他制御情報の一覧を取得する。
    #
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori/lockdel.data/api02107v03.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori/lockdel.data/api02107v03_err.pdf
    def list
      req = {
        "Request_Number" => "00",
        "Karte_Uid" => orca_api.karte_uid,
      }

      Result.new(orca_api.call("/api21/medicalmodv37", body: { "medicalv3req7" => req }))
    end

    # 排他制御情報をすべて解除する。
    #
    # 排他解除は残っている一時データも削除する。処理中のオルカＵＩＤの排他解除を行った場合の不具合には対応できない。
    #
    # また、日レセAPIの制限で、解除対象の排他時間が処理時間より１分以内の場合は解除できない。
    # この場合のApi_Resultは「E14」、Api_Result_Messageは「端末展開中と思われる排他時間です。
    # 端末が展開中でないことを確認して下さい。」です。排他解除が必要であれば、１分後に再度送信して下さい。
    #
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori/lockdel.data/api02107v03.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori/lockdel.data/api02107v03_err.pdf
    def unlock_all
      req = {
        "Request_Number" => "01",
        "Karte_Uid" => orca_api.karte_uid,
        "Delete_Information" => {
          "Delete_Class" => "All",
        },
      }
      res = Result.new(orca_api.call("/api21/medicalmodv37", body: { "medicalv3req7" => req }))
      if res.api_result != "S40"
        return res
      end

      req = {
        "Request_Number" => res.response_number,
        "Karte_Uid" => res.karte_uid,
        "Orca_Uid" => res.orca_uid,
        "Delete_Information" => res.delete_information,
        "Select_Answer" => "Ok",
      }
      Result.new(orca_api.call("/api21/medicalmodv37", body: { "medicalv3req7" => req }))
    end
  end
end
