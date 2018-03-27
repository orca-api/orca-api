require_relative "service"

module OrcaApi
  # 照会業務を扱うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19095
  class FindService < Service
    # 検索指示のリクエストを行う際の設定値を返す
    #
    # 対象の設定値は以下。
    #  * 状態１情報
    #  * 状態２情報
    #  * 状態３情報
    #  * 減免事由情報
    #  * 特記事項情報
    #  * 保険情報
    #  * 公費情報
    #
    # @param [String] base_date
    #   基準日。YYYY-mm-dd形式。省略時はシステム日付。
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19095#api4
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findinfv3.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findinfv3_err.pdf
    def settings(base_date = "")
      req = {
        "Request_Number" => "01",
        "Base_Date" => base_date,
      }

      Result.new(orca_api.call("/orca13/findinfv3", body: { "findinfv3req" => req }))
    end
  end
end
