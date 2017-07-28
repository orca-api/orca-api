# coding: utf-8

module OrcaApi
  class PatientService < Service
    module Create
      # 患者情報の登録の結果を表現するクラス
      class Result < ::OrcaApi::PatientService::Result
        def duplicated_patient_candidates
          @body["Patient2_Information"] || []
        end
      end
    end
  end
end
