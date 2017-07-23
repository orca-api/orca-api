# coding: utf-8

require_relative "../patient_information"
require_relative "create/request_body"
require_relative "create/result"

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
        res = Result.new(orca_api.call(api_path, body: body))
        if !res.ok? && allow_duplication && !res.duplicated_patient_candidates.empty?
          body.request_number = "02"
          body.orca_uid = res.orca_uid
          body.select_answer = "Ok"
          res = Result.new(orca_api.call(api_path, body: body))
        end
        res
      end
    end
  end
end
