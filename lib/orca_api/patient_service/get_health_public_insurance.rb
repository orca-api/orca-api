# coding: utf-8

module OrcaApi
  class PatientService < Service
    # 患者保険・公費情報の取得
    module GetHealthPublicInsurance
      # 患者保険・公費情報の取得の結果を表現するクラス
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
          @body.select { |k, _|
            KEYS.include?(k)
          } || {}
        end
      end

      def get_health_public_insurance(id)
        api_path = "/orca12/patientmodv32"
        req_name = "patientmodreq"

        body = {
          req_name => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => "",
            "Patient_Information" => {
              "Patient_ID" => id.to_s,
            }
          }
        }
        res = Result.new(orca_api.call(api_path, body: body))

        unlock(api_path,
               req_name => {
                 "Request_Number" => "99",
                 "Karte_Uid" => res.karte_uid,
                 "Orca_Uid" => res.orca_uid,
                 "Patient_Information" => res.patient_information,
               })

        res
      end
    end
  end
end
