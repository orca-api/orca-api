# coding: utf-8

require_relative "../patient_information"

module OrcaApi
  class PatientService
    # 患者情報の取得
    module Get
      API_PATH = "/orca12/patientmodv31".freeze
      private_constant :API_PATH

      REQ_NAME = "patientmodreq".freeze
      private_constant :REQ_NAME

      def get(id, associations: [])
        body = {
          REQ_NAME => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => id.to_s,
            "Patient_Mode" => "Modify",
            "Orca_Uid" => "",
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
                 "Patient_ID" => res["Patient_Information"]["Patient_ID"],
                 "Orca_Uid" => res["Orca_Uid"],
               })

        PatientInformation.new(res["Patient_Information"]).tap { |patient|
          associations.each do |association|
            patient.send("#{association}=", send("get_#{association}", id))
          end
        }
      end
    end
  end
end
