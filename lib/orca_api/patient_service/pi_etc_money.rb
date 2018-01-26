require_relative "pi_money_common"

module OrcaApi
  class PatientService < Service
    # 他一部負担額情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
    class PiEtcMoney < PiMoneyCommon
      # 他一部負担額一覧を取得する
      #
      # @param [String] id
      #   患者ID
      # @param [String] pi_id
      #   公費ID
      # @param [String] number
      #   公費負担額の連番
      # @param [String] start_date
      #   公費負担額の開始日
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
      def get(id, pi_id, number, start_date)
        res = call_01(id)
        if !res.ok?
          return res
        end
        res = call_02(pi_id, res)
        if !res.ok?
          return res
        end
        res = call_04(number, start_date, res)
        res
      ensure
        unlock(res)
      end

      # 他一部負担額を更新する
      #
      # @param [String] id
      #   患者ID
      # @param [String] pi_id
      #   公費ID
      # @param [String] number
      #   公費負担額の連番
      # @param [String] start_date
      #   公費負担額の開始日
      # @param [Hash] args
      #   他一部負担額情報
      #   * "Pi_Etc_Money_Mode" (String)
      #     処理区分。
      #     "Modify": 更新、"Delete": 削除、変更なしは空白。
      #     更新は処理単位毎に送信内容で一括更新処理を行います。
      #     削除は処理単位毎にテーブルを一括削除します。
      #   * "Pi_Etc_Money_Info" (Array<Hash>)
      #     他一部負担額情報。
      #     処理区分が"Delete"の場合は不要です。
      #     * "Pi_Etc_Money_Date" (String)
      #       年月日。YYYY-mm-dd形式。必須。
      #     * "Pi_Etc_Money_InOut" (String)
      #       入外区分。1: 入院、2: 入院外。必須。
      #     * "Pi_Etc_Money_Money" (String)
      #       他一部負担額
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
      def update(id, pi_id, number, start_date, args)
        locked_result = res = call_01(id)
        if !res.ok?
          return res
        end
        res = call_02(pi_id, res)
        if !res.ok?
          return res
        end
        res = call_04(number, start_date, res)
        if !res.ok?
          return res
        end
        res = call_05(args, res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock(locked_result)
      end

      private

      def call_04(number, start_date, res)
        req = {
          "Request_Number" => "04",
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "PublicInsurance_Information" => {
            "PublicInsurance_Id" => res.pi_money_information["Sel_PublicInsurance_Id"],
          },
          "Pi_Money_Sel_Information" => {
            "Pi_Money_Sel_Number" => number.to_s,
            "Pi_Money_Sel_StartDate" => start_date.to_s,
          },
        }
        call(req)
      end

      def call_05(args, res)
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "PublicInsurance_Information" => {
            "PublicInsurance_Id" => res.pi_money_information["Sel_PublicInsurance_Id"],
          },
          "Pi_Money_Sel_Information" => {
            "Pi_Money_Sel_Number" => res.pi_etc_money_information["Sel_Pi_Etc_Money_Number"],
            "Pi_Money_Sel_StartDate" => res.pi_etc_money_information["Sel_Pi_Etc_Money_StartDate"],
          },
          "Pi_Etc_Money_Information" => args,
        }
        call(req)
      end
    end
  end
end
