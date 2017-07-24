# coding: utf-8

module OrcaApi
  class PatientService
    # 患者情報の取得
    module Get
      def get(id)
        api_path = "/orca12/patientmodv31"
        req_name = "patientmodreq"

        body = {
          req_name => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => id.to_s,
            "Patient_Mode" => "Modify",
            "Orca_Uid" => "",
          }
        }
        res = Result.new(orca_api.call(api_path, body: body))

        unlock(api_path,
               req_name => {
                 "Request_Number" => "99",
                 "Karte_Uid" => res.karte_uid,
                 "Patient_ID" => res.patient_information["Patient_ID"],
                 "Orca_Uid" => res.orca_uid,
               })

        res
      end
    end
  end
end
