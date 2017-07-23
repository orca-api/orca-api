# coding: utf-8

require_relative "../../result"

module OrcaApi
  class PatientService
    module Create
      # 患者情報の登録の結果を表現するクラス
      class Result < ::OrcaApi::Result
        def patient_information
          @body["Patient_Information"]
        end

        def duplicated_patient_candidates
          @body["Patient2_Information"] || []
        end
      end
    end
  end
end
