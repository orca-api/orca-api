# coding: utf-8

module OrcaApi
  class PatientService
    # 患者情報の更新
    module Update
      def update(id, patient_information)
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
        if !res.ok?
          # TODO: エラー処理
        end

        req = body[req_name]
        req["Request_Number"] = res.response_number
        req["Patient_ID"] = res.patient_information["Patient_ID"]
        req["Orca_Uid"] = res.orca_uid
        req["Patient_Information"] = patient_information
        res = Result.new(orca_api.call(api_path, body: body))
        if !res.ok?
          # TODO: エラー処理
        end

        res
      end
    end
  end
end
