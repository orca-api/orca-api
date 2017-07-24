# coding: utf-8

module OrcaApi
  class PatientService
    module Get
      # 患者情報の取得の結果を表現するクラス
      class Result < ::OrcaApi::PatientService::Result
        attr_accessor :health_public_insurance_result

        def health_public_insurance
          @health_public_insurance_result.health_public_insurance
        end
      end
    end
  end
end
