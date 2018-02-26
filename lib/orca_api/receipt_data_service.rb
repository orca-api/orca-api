require_relative "service"

module OrcaApi
  # レセ電データ取得(一括)を扱うサービスを表現したクラス
  #
  # レセ電データ取得(一括)の流れを以下に示す。
  #
  #  * (1) 医保分のレセ電データ作成時に必要な次の情報取得する: list_effective_information
  #     * Effective_Period_Information: Start_Month、End_Month
  #     * Effective_InsuranceProvider_Information: InsuranceProvider_Number
  #  * (2) 処理実施: create
  #     * 保険者番号、期間指定を行い、レセ電データの作成を開始する。大容量データAPIの呼び出しに必要なData_Idを得る。
  #     * 機能制限: 月途中に医療機関コードが変更されている月のレセ電データの作成については、日レセの通常業務と同様出来きません。
  #  * (3) 処理確認: created
  #     * このメソッドを定期的に呼び出して処理状況を確認する。
  #  * (4) 大容量データAPIでレセ電データ(CSV)の取得
  #     * (2)で得たData_Idを元に、大容量データを扱うサービス BlobService を使用して、生成したCSVを取得する
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/21036
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori/receipt_list.data/api44v03.pdf
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori/receipt_list.data/api44v03_err.pdf
  class ReceiptDataService < Service
    # 医保分のレセ電データ作成時に必要な情報取得する処理の結果を表現するクラス
    #
    # 情報がない場合でも `#ok?` がtrueを返し、以下でいずれも空の配列を返す。
    #
    #  * `#effective_period_information` と `#["Effective_Period_Information"]`
    #  * `#effective_insuranceprovider_information` と `#["Effective_InsuranceProvider_Information"]`
    class ListEffectiveInformationResult < ::OrcaApi::Result
      def body
        @body ||= {
          "Effective_Period_Information" => [],
          "Effective_InsuranceProvider_Information" => [],
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
    #
    # 具体的には、
    #
    #  * 医保(submission_modeが02〜04)の場合にシステム管理「1001 医療機関情報」で
    #    医療機関コードの変更が行われているときに医療機関コード毎の期間を返却する。
    #    選択区分(Effective_Period_Information.Info_Period_Select_Mode)に「Ng」が返却されている期間については、
    #    月途中に医療機関コードが変更されているのでcreateの時に設定できない。
    #  * 社保(submission_modeが02)の場合にシステム管理「2005 レセプト・総括印刷情報」の
    #    直接請求を行う保険者に設定してある保険者情報を返却する。
    #    また、直接請求を行う保険者以外の社保分として保険者番号「００００００００」、
    #    保険者名称「直接請求する保険者以外」を返却する。
    def list_effective_information(perform_month, submission_mode)
      req = default_request.merge(
        "Request_Number" => "00",
        "Karte_Uid" => orca_api.karte_uid,
        "Perform_Month" => perform_month,
        "Submission_Mode" => submission_mode
      )
      call(req, ListEffectiveInformationResult)
    end

    # 処理実施
    def create(args)
      req = default_request.merge(args).merge(
        "Request_Number" => "01",
        "Karte_Uid" => orca_api.karte_uid
      )
      call(req)
    end

    # 処理確認
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
        "Perform_Date" => now.strftime("%Y-%m"),
        "Perform_Month" => now.strftime("%Y-%m"),
        "Ac_Date" => now.strftime("%Y-%m-%d"),
        "Receipt_Mode" => "02",
        "InOut" => "IO",
        "Check_Mode" => "",
      }
    end

    def call(req, result_class = Result)
      result_class.new(orca_api.call("/orca44/receiptdatamakev3", body: { "receiptdata_makev3req" => req }))
    end
  end
end
