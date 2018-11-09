# frozen_string_literal: true

module OrcaApi
  class PatientService < Service
    # 患者労災・自賠責保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v033.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v033_err.pdf
    class AccidentInsurance < Service
      # 取得
      def get(id)
        res = call_01(id)
        if !res.locked?
          unlock(res)
        end
        res
      end

      # 登録・更新・削除
      def update(id, params)
        res = call_01(id)
        if !res.locked?
          locked_result = res
        end
        if !res.ok?
          return res
        end

        res = call_02(params, res)
        if !res.ok?
          return res
        end

        res = call_03(res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock(locked_result)
      end

      private

      def call_01(id)
        req = {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => "",
          "Patient_Information" => {
            "Patient_ID" => id.to_s,
          }
        }
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      def call_02(params, previous_result)
        res = previous_result
        req = params.merge(
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information
        )
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      def call_03(previous_result)
        res = previous_result
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          "Accident_Insurance_Information" => res["Accident_Insurance_Information"],
        }
        Result.new(orca_api.call("/orca12/patientmodv33", body: make_body(req)))
      end

      def unlock(locked_result)
        if locked_result&.respond_to?(:orca_uid)
          req = {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => locked_result.orca_uid,
            "Patient_Information" => locked_result.patient_information,
          }
          orca_api.call("/orca12/patientmodv33", body: make_body(req))
        end
      end

      def make_body(req)
        { "patientmodv3req3" => req }
      end
    end
  end
end
