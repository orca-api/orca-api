# coding: utf-8

require_relative "create/result"

module OrcaApi
  class PatientService
    # 患者情報の登録
    module Create
      def create(patient, allow_duplication: false)
        api_path = "/orca12/patientmodv31"
        body = {
          "patientmodreq" => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => "*",
            "Patient_Mode" => "New",
            "Orca_Uid" => "",
            "Select_Answer" => "",
            "Patient_Information" => patient,
          }
        }
        res = Result.new(orca_api.call(api_path, body: body))
        if !res.ok? && allow_duplication && !res.duplicated_patient_candidates.empty?
          req = body["patientmodreq"]
          req["Request_Number"] = res.response_number
          req["Orca_Uid"] = res.orca_uid
          req["Select_Answer"] = "Ok"
          res = Result.new(orca_api.call(api_path, body: body))
        end
        res
      end
    end
  end
end
