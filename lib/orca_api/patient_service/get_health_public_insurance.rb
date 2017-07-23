# coding: utf-8

require_relative "../health_public_insurance"

module OrcaApi
  class PatientService
    # 患者保険・公費情報の取得
    module GetHealthPublicInsurance
      API_PATH = "/orca12/patientmodv32".freeze
      private_constant :API_PATH

      REQ_NAME = "patientmodreq".freeze
      private_constant :REQ_NAME

      def get_health_public_insurance(id)
        body = {
          REQ_NAME => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => "",
            "Patient_Information" => {
              "Patient_ID" => id.to_s,
            }.freeze
          }
        }
        res0 = orca_api.call(API_PATH, body: body)
        res = res0.first[1]
        if res["Request_Number"].to_i <= res["Response_Number"].to_i
          # TODO: エラー処理
        end

        unlock(API_PATH,
               REQ_NAME => {
                 "Request_Number" => "99",
                 "Karte_Uid" => res["Karte_Uid"],
                 "Orca_Uid" => res["Orca_Uid"],
                 "Patient_Information" => res["Patient_Information"],
               })

        HealthPublicInsurance.new(res)
      end
    end
  end
end
