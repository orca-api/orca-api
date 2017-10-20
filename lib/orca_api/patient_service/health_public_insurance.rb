module OrcaApi
  class PatientService < Service
    # 患者保険・公費情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class HealthPublicInsurance < Service
      # 患者保険・公費情報の取得・更新の結果を表現するクラス
      class Result < ::OrcaApi::Result
        KEYS = Set.new(
          %w(
            Patient_Information
            HealthInsurance_Information
            PublicInsurance_Information
            HealthInsurance_Combination_Information
          )
        )

        def health_public_insurance
          body.select { |k, _|
            KEYS.include?(k)
          } || {}
        end
      end

      # 取得
      def get(id)
        res = call_orca12_patientmodv32_01(id)
        if !res.locked?
          unlock_orca12_patientmodv32(res)
        end
        res
      end

      # 登録・更新・削除
      def update(id, params)
        res = call_orca12_patientmodv32_01(id)
        if !res.locked?
          locked_result = res
        end
        if !res.ok?
          return res
        end
        res = call_orca12_patientmodv32_02(params, res)
        if !res.ok?
          return res
        end
        res = call_orca12_patientmodv32_03(res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock_orca12_patientmodv32(locked_result)
      end

      private

      def call_orca12_patientmodv32_01(id)
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
        Result.new(orca_api.call("/orca12/patientmodv32", body: body))
      end

      def call_orca12_patientmodv32_02(params, previous_result)
        res = previous_result
        body = {
          "patientmodreq" => params.merge(
            "Request_Number" => res.response_number,
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => res.orca_uid,
            "Patient_Information" => res.patient_information
          )
        }
        Result.new(orca_api.call("/orca12/patientmodv32", body: body))
      end

      def call_orca12_patientmodv32_03(previous_result)
        res = previous_result
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
        }
        if res["HealthInsurance_Information"]
          req["HealthInsurance_Information"] = res["HealthInsurance_Information"]
        end
        if res["PublicInsurance_Information"]
          req["PublicInsurance_Information"] = res["PublicInsurance_Information"]
        end
        Result.new(orca_api.call("/orca12/patientmodv32", body: { "patientmodreq" => req }))
      end

      def unlock_orca12_patientmodv32(locked_result)
        if locked_result && locked_result.respond_to?(:orca_uid)
          body = {
            "patientmodreq" => {
              "Request_Number" => "99",
              "Karte_Uid" => orca_api.karte_uid,
              "Orca_Uid" => locked_result.orca_uid,
              "Patient_Information" => locked_result.patient_information,
            }
          }
          orca_api.call("/orca12/patientmodv32", body: body)
        end
      end
    end
  end
end
