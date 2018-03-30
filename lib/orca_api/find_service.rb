require_relative "service"

module OrcaApi
  # 照会業務を扱うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19095
  class FindService < Service
    # 検索結果を扱うクラス
    class FindResult < ::OrcaApi::Result
      # 処理中かどうか
      #
      # @return [Boolean] 処理中であればtrue、そうでなければfalse。
      def doing?
        api_result == "E1040"
      end
    end

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

    # 検索条件や検索結果返却区分を設定して、検索処理を開始するための指示を行う。この時点では検索結果は返却しない。
    #
    # @param [Hash] args
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19095#api1
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findv31.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findv31_err.pdf
    def find(args)
      req = args.merge(
        "Request_Number" => "01",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req)
    end

    # 検索が完了していた場合、検索結果を返却する。
    #
    # 検索中の場合は `result.doing?` が `true` を返すので、1秒間に1回等の間隔で検索結果返却を呼び出して、検索完了を待つ。
    # 1度に返却できる患者情報の数には限りがあるため、患者情報のうちN件目からM件までという指定をする。デフォルトは1件目から200件目(件数は200)。
    #
    # @param [Hash] args
    #   * "Orca_Uid" (String)
    #     オルカUID。必須。
    #   * "Selection" (Hash)
    #     検索結果返却開始・終了件数
    #     * "First" (String)
    #       範囲指定の開始値(［Ｎ件目からＭ件目］のＮ)。
    #       未設定時初期値は1
    #     * "Last" (String)
    #       範囲指定の終了値(［Ｎ件目からＭ件目］のＭ)。
    #       未設定時初期値は200
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19095#api2
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findv32.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findv32_err.pdf
    def result(args)
      req = args.merge(
        "Request_Number" => "02",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req, FindResult)
    end

    # 日レセサーバ上の検索結果等の接続情報を消去する
    #
    # @param [Hash] args
    #   * "Orca_Uid" (String)
    #     オルカUID。必須。
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19095#api3
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findv399.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_find.data/findv399_err.pdf
    def finish(args)
      req = args.merge(
        "Request_Number" => "99",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req)
    end

    private

    def call(req, result_class = Result)
      result_class.new(orca_api.call("/orca13/findv3", body: { "findv3req" => req }))
    end
  end
end
