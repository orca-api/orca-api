require_relative "service"

module OrcaApi
  # 排他制御解除を行うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/20796
  class LockService < Service
    # 排他制御情報の一覧を取得する
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
  end
end
