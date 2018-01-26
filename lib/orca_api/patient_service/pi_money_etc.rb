module OrcaApi
  class PatientService < Service
    # 患者公費他一部負担額を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
    class PiMoneyEtc < Service
      # 他一部負担額一覧を取得する
      #
      # @params [String] id
      #   患者ID
      # @params [String] pi_id
      #   公費ID
      # @params [String] number
      #   公費負担額の連番
      # @params [String] start_date
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

      private

      def call_01(id)
        req = {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_Information" => {
            "Patient_ID" => id.to_s,
          }
        }
        call(req)
      end

      def call_02(pi_id, res)
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "PublicInsurance_Information" => {
            "PublicInsurance_Id" => pi_id.to_s,
          },
        }
        call(req)
      end

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

      def call(req)
        Result.new(orca_api.call("/orca12/patientmodv35", body: { "patientmodv3req5" => req }))
      end

      def unlock(locked_result)
        if locked_result && locked_result.respond_to?(:orca_uid)
          req = {
            "Request_Number" => "99",
            "Karte_Uid" => locked_result.karte_uid,
            "Orca_Uid" => locked_result.orca_uid,
          }
          call(req)
        end
      end
    end
  end
end
