module OrcaApi
  class PatientService < Service
    # 患者労災・自賠責保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v033.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v033_err.pdf
    class AccidentInsurance < Service
      # 取得
      def get(id)
        res = call_orca12_patientmodv33_01(id)
        if !res.locked?
          unlock_orca12_patientmodv33(res)
        end
        res
      end

      # 登録・更新・削除
      def update(id, params)
        res = call_orca12_patientmodv33_01(id)
        if !res.locked?
          locked_result = res
        end
        if !res.ok?
          return res
        end
        res = call_orca12_patientmodv33_02(params, res)
        if !res.ok?
          return res
        end
        res = call_orca12_patientmodv33_03(res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock_orca12_patientmodv33(locked_result)
      end

      private

      def call_orca12_patientmodv33_01(id)
        body = {
          "patientmodreq" => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => "",
            "Patient_Information" => {
              "Patient_ID" => id.to_s,
            }
          }
        }
        Result.new(orca_api.call("/orca12/patientmodv33", body: body))
      end

      def call_orca12_patientmodv33_02(params, previous_result)
        res = previous_result
        req = params.merge(
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information
        )
        Result.new(orca_api.call("/orca12/patientmodv33", body: { "patientmodreq" => req }))
      end

      def call_orca12_patientmodv33_03(previous_result)
        res = previous_result
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "Accident_Insurance_Information" => res["Accident_Insurance_Information"],
        }
        Result.new(orca_api.call("/orca12/patientmodv33", body: { "patientmodreq" => req }))
      end

      def unlock_orca12_patientmodv33(locked_result)
        if locked_result && locked_result.respond_to?(:orca_uid)
          body = {
            "patientmodreq" => {
              "Request_Number" => "99",
              "Karte_Uid" => orca_api.karte_uid,
              "Orca_Uid" => locked_result.orca_uid,
              "Patient_Information" => locked_result.patient_information,
            }
          }
          orca_api.call("/orca12/patientmodv33", body: body)
        end
      end
    end
  end
end
