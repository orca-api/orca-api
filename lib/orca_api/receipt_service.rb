require_relative "service"

module OrcaApi
  # レセプト(明細書)を扱うサービスを表現したクラス
  #
  # レセプトの作成から印刷までの流れを以下に示す。
  #
  #  * (1) レセプト作成
  #    * (1)-1 作成指示: create
  #    * (1)-2 作成確認: created
  #      * 作成が完了するまで定期的に(1)-2を繰り返す
  #  * (2) レセプト印刷
  #    * (2)-1 印刷指示: print
  #    * (2)-2 印刷結果確認: printed
  #      * 印刷(PDFの生成)が完了するまで定期的に(2)-2を繰り返す
  #  * (3) PDF(大容量データ)の取得
  #    * 大容量データを扱うサービス BlobService を使用して、生成したPDFを取得する
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19238
  class ReceiptService < Service
    # 作成確認と印刷結果確認に共通の確認結果を扱うクラス
    class CheckResult < ::OrcaApi::Result
      # 処理中かどうか
      #
      # @return [Boolean] 処理中であればtrue、そうでなければfalse。
      def doing?
        api_result == "E70"
      end
    end

    # レセプト作成:作成指示
    #
    # @param [Hash] args
    #   * "Perform_Date" (String)
    #     実施年月日。YYYY-mm-dd形式。
    #   * "Perform_Month" (String)
    #     診療年月。処理区分がAll のとき必須。
    #   * "InOut" (String)
    #     入外区分。必須。I：入院、O：入院外。
    #   * "Receipt_Mode" (String)
    #     処理区分。All：一括作成　All以外：個別作成。
    #   * "Print_Mode" (String)
    #     印刷モード。Check：点検用　Check以外：提出用。
    #     個別作成でCheck(点検用)のとき、点検用は平成２０年４月診療分から対応のため、
    #     診療年月が平成２０年３月以前の場合は提出用として作成します。
    #   * "Submission_Mode" (String)
    #     提出先。必須。
    #     医保 01:全件 02:社保 03:国保 04:広域 労災 05 自賠責 06:新様式 07:従来様式 08:第三者行為 公害 09。
    #   * "Patient_Information" (Array<Hash>)
    #     個別対象患者一覧。個別作成のとき必須。配列の最大サイズは100。
    #     配列の内容は以下のHash。
    #     * "Patient_ID" (String)
    #       患者番号
    #     * "Patient_Perfrm_Month" (String)
    #       診療年月
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_receipt.data/receiptmakev3.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_receipt.data/receiptmakev3_err.pdf
    def create(args)
      req = args.merge(
        {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => "",
        }
      )

      Result.new(orca_api.call("/orca42/receiptmakev3", body: { "receipt_makev3req" => req }))
    end

    # レセプト作成:作成確認
    #
    # @param [Hash] args
    #   * "Orca_Uid" (String)
    #     オルカUID。必須。
    #   * "Perform_Date" (String)
    #     実施年月日。YYYY-mm-dd形式。
    #   * "Perform_Month" (String)
    #     診療年月。処理区分がAll のとき必須。
    #   * "InOut" (String)
    #     入外区分。必須。I：入院、O：入院外。
    #   * "Receipt_Mode" (String)
    #     処理区分。All：一括作成　All以外：個別作成。
    #   * "Print_Mode" (String)
    #     印刷モード。Check：点検用　Check以外：提出用。
    #     個別作成でCheck(点検用)のとき、点検用は平成２０年４月診療分から対応のため、
    #     診療年月が平成２０年３月以前の場合は提出用として作成します。
    #   * "Submission_Mode" (String)
    #     提出先。必須。
    #     医保 01:全件 02:社保 03:国保 04:広域 労災 05 自賠責 06:新様式 07:従来様式 08:第三者行為 公害 09。
    # @return [OrcaApi::CheckResult]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_receipt.data/receiptmakev3.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_receipt.data/receiptmakev3_err.pdf
    def created(args)
      req = args.merge(
        {
          "Request_Number" => "02",
          "Karte_Uid" => orca_api.karte_uid,
        }
      )

      CheckResult.new(orca_api.call("/orca42/receiptmakev3", body: { "receipt_makev3req" => req }))
    end

    # レセプト印刷:印刷指示
    #
    # @param [Hash] args
    #   * "Orca_Uid" (String)
    #     オルカUID。必須。
    #   * "Perform_Date" (String)
    #     実施年月日。YYYY-mm-dd形式。
    #   * "Perform_Month" (String)
    #     診療年月。処理区分がAll のとき必須。
    #   * "InOut" (String)
    #     入外区分。必須。I：入院、O：入院外。
    #   * "Receipt_Mode" (String)
    #     処理区分。All：一括作成　All以外：個別作成。
    #   * "Print_Mode" (String)
    #     印刷モード。Check：点検用　Check以外：提出用。
    #     個別作成でCheck(点検用)のとき、点検用は平成２０年４月診療分から対応のため、
    #     診療年月が平成２０年３月以前の場合は提出用として作成します。
    #   * "Submission_Mode" (String)
    #     提出先。必須。
    #     医保 01:全件 02:社保 03:国保 04:広域 労災 05 自賠責 06:新様式 07:従来様式 08:第三者行為 公害 09。
    #   * "Receipt_Information" (Hash)
    #     個別作成明細一覧。印刷モードが個別印刷のとき必須。
    #     作成確認(#created)の結果に含まれるレセプト一覧(Receipt_Information)に対して、
    #     印刷したいレセプトに印刷指示を設定したもの。
    #     * "Submission_Information" (Array<Hash>)
    #       配列の内容は以下のHash。
    #       * "Submission_Position" (String)
    #         連番。必須。
    #       * "Detail_Information" (Array<Hash>)
    #         配列の内容は以下のHash。
    #         * "Detail_Position" (String)
    #           連番。必須。
    #         * "Print_Instruct" (String)
    #           印刷指示。Yes：印刷　Yes以外：印刷しない。
    #         * "Submission_Identification" (String)
    #           提出先
    #         * "Submission_Code" (String)
    #           種別等コード。必須。
    #         * "Submission_Type" (String)
    #           種別
    #         * "Count" (String)
    #           件数
    #         * "Number_Of_Sheets" (String)
    #           枚数
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_receipt.data/receiptprintv3.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_receipt.data/receiptprintv3_err.pdf
    def print(args)
      req = args.merge(
        {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
        }
      )

      Result.new(orca_api.call("/orca42/receiptprintv3", body: { "receipt_printv3req" => req }))
    end

    def printed(args)
      req = args.merge(
        {
          "Request_Number" => "02",
          "Karte_Uid" => orca_api.karte_uid,
        }
      )

      CheckResult.new(orca_api.call("/orca42/receiptprintv3", body: { "receipt_printv3req" => req }))
    end
  end
end
