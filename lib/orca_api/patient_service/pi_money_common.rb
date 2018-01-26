module OrcaApi
  class PatientService < Service
    # 患者公費負担額・他一部負担額情報を扱うサービスの共通処理
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api5
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v035_err.pdf
    class PiMoneyCommon < Service
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
