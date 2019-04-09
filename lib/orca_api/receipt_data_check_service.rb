require_relative "service"

module OrcaApi
  # チェック用個別レセ電データ取得
  #
  # レセ電データ取得(一括)の流れと同様
  #
  #  1. 医保分のレセ電データ作成時に必要な次の情報取得する: list_effective_information
  #  2. 処理実施: create
  #  3. 処理確認: created
  #  4. 大容量データAPIでレセ電データ(CSV)の取得
  #
  # @see https://www.orcamo.co.jp/api-council/members/standards/?haori_receiptdata_check
  class ReceiptDataCheckService < Service
    # 医保分のレセ電データ作成時に必要な情報取得する処理の結果を表現するクラス
    class ListEffectiveInformationResult < ::OrcaApi::Result
      def body
        @body ||= {
          "Effective_Period_Information" => [],
          "InsuranceProvider_Information" => [],
        }.merge(self.class.parse(@raw))
      end
    end

    # 処理確認の結果を扱うクラス
    class CreatedResult < ::OrcaApi::Result
      # 処理中かどうか
      #
      # @return [Boolean] 処理中であればtrue、そうでなければfalse。
      def doing?
        api_result == "E70"
      end
    end

    # 医保分のレセ電データ作成時に必要な情報取得する
    # @param [Hash] args
    #   * Submission_Mode (String)
    #     提出先。
    #     医保の場合、02:社保 03:国保 04:広域。労災の場合05。
    #     必須。
    #   * Perform_Date (String)
    #     実施年月日。YYYY-mm-dd形式。省略した場合は現在年月日。
    #   * Perform_Month (String)
    #     診療年月。YYYY-mm形式。省略した場合は現在年月。
    #   * Ac_Date (String)
    #     請求年月日。YYYY-mm-dd形式。省略した場合は現在年月日。
    #   * Create_Mode (String)
    #     作成モード。Check:点検用 Check以外:提出用。
    # @return [OrcaApi::ReceiptDataCheckService::ListEffectiveInformationResult]
    #   日レセからのレスポンス
    def list_effective_information(args)
      req = default_request.merge(args).merge(
        "Request_Number" => "00",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req, ListEffectiveInformationResult)
    end

    # 処理実施
    #
    # @param [Hash] args
    #   * Submission_Mode (String)
    #     提出先。
    #     医保の場合、02:社保 03:国保 04:広域。労災の場合05。
    #     必須。
    #   * Perform_Date (String)
    #     実施年月日。YYYY-mm-dd形式。省略した場合は現在年月日。
    #   * Perform_Month (String)
    #     診療年月。YYYY-mm形式。省略した場合は現在年月。
    #   * Ac_Date (String)
    #     請求年月日。YYYY-mm-dd形式。省略した場合は現在年月日。
    #   * Create_Mode (String)
    #     作成モード。Check:点検用 Check以外:提出用。
    #   * Check_Mode (String)
    #     レセ電データチェック Yes:チェックする Yes以外:チェックしない。省略した場合は「チェックしない」。
    #   * InsuranceProvider_Number (String)
    #     直接請求する保険者番号
    #   * Start_Month (String)
    #     期間指定(開始年月)。YYYY-mm形式。
    #   * End_Month (String)
    #     期間指定(終了年月)。YYYY-mm形式。
    #   * Patient_Information (Array<Hash>)
    #     個別対象患者一覧。個別作成のとき必須。配列の最大サイズは100。
    #     配列の内容は以下のHash。
    #     * Patient_ID (String)
    #       患者番号
    #     * Patient_Perfrm_Month (String)
    #       診療年月
    #     * Patient_InOut (String)
    #       入外区分 I:入院 O:入院外 IO、OI:入院、入院外
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    def create(args)
      req = default_request.merge(args).merge(
        "Request_Number" => "01",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req)
    end

    # 処理確認
    #
    # @param [Hash] args
    #   `#create` の `args` に以下を追加したもの
    #   * Orca_Uid (String)
    #     オルカＵＩＤ。必須。
    # @return [OrcaApi::ReceiptDataCheckService::CreatedResult]
    #   日レセからのレスポンス
    def created(args)
      req = default_request.merge(args).merge(
        "Request_Number" => "02",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req, CreatedResult)
    end

    private

    def default_request
      now = Time.now
      {
        "Perform_Date" => now.strftime("%Y-%m-%d"),
        "Perform_Month" => now.strftime("%Y-%m"),
        "Ac_Date" => now.strftime("%Y-%m-%d"),
        "Create_Mode" => "Check",
        "InOut" => "IO",
        "Check_Mode" => "No",
      }
    end

    def call(req, result_class = Result)
      result_class.new(orca_api.call("/orca44/receiptdatacheckmakev3", body: { "receiptdata_check_makev3req" => req }))
    end
  end
end
