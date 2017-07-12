# coding: utf-8

require_relative "../patient_information"
require_relative "create/request_body"

module OrcaApi
  class PatientService
    # 患者情報の登録
    module Create
      def create(patient, allow_duplication: false)
        if patient.is_a?(Hash)
          patient = PatientInformation.new(patient)
        end

        api_path = "/orca12/patientmodv31"

        body = RequestBody.new(karte_uid: orca_api.karte_uid, patient_information: patient)
        res0 = orca_api.call(api_path, body: body)
        res = res0.first[1]
        if res["Response_Number"] == "02"
          if allow_duplication
            body.request_number = "02"
            body.orca_uid = res["Orca_Uid"]
            body.select_answer = "Ok"
            res0 = orca_api.call(api_path, body: body)
            res = res0.first[1]
          else
            # TODO: 適切な例外クラスを投げる
            raise "PatientDuplicated"
          end
        end

        patient.update(res["Patient_Information"])
      end
    end
  end
end
