require_relative "pi_money_common"

module OrcaApi
  class PatientService < Service
    # 患者公費負担額を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
    class PiMoney < PiMoneyCommon
      # 公費負担額登録対象の公費一覧を取得する
      #
      # @param [String] id
      #   患者ID
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
      def target_of(id)
        res = call_01(id)
        unlock(res)
        res
      end

      # 公費負担額一覧を取得する
      #
      # @param [String] id
      #   患者ID
      # @param [String] pi_id
      #   公費ID
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
      def get(id, pi_id)
        res = call_01(id)
        if !res.ok?
          return res
        end

        call_02(pi_id, res)
      ensure
        unlock(res)
      end

      def fetch(id, pi_id)
        call_00(id, pi_id)
      end

      # 公費負担額を更新する
      #
      # @param [String] id
      #   患者ID
      # @param [String] pi_id
      #   公費ID
      # @param [Hash] args
      #   公費負担額情報
      #   * "Pi_Money_Mode" (String)
      #     処理区分。
      #     "Modify": 更新、"Delete": 削除、変更なしは空白。
      #     更新は処理単位毎に送信内容で一括更新処理を行います。
      #     削除は処理単位毎にテーブルを一括削除します。
      #   * "Pi_Money_Info" (Array<Hash>)
      #     公費負担額情報。
      #     処理区分が"Delete"の場合は不要です。
      #     * "Pi_Money_Line_Mode" (String)
      #       行処理区分。
      #       "New": 新規追加、"Delete": 行削除。
      #       1行削除の場合は"Delete"を必ず指定してください。
      #       空白で連番ありは更新、連番なしは新規追加です。
      #     * "Pi_Money_Number" (String)
      #       連番
      #     * "Pi_Money_StartDate" (String)
      #       開始日。必須。
      #     * "Pi_Money_ExpiredDate" (String)
      #       終了日
      #     * "Pi_Money_Money1" (String)
      #       負担額１
      #     * "Pi_Money_Money2" (String)
      #       負担額１
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
      def update(id, pi_id, args)
        locked_result = res = call_01(id)
        if !res.ok?
          return res
        end

        res = call_02(pi_id, res)
        if !res.ok?
          return res
        end

        res = call_03(args, res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock(locked_result)
      end

      private

      def call_03(args, res)
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "PublicInsurance_Information" => {
            "PublicInsurance_Id" => res.pi_money_information["Sel_PublicInsurance_Id"],
          },
          "Pi_Money_Information" => args,
        }
        call(req)
      end
    end
  end
end
