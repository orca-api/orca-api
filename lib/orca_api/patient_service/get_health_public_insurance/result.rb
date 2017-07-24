# coding: utf-8

module OrcaApi
  class PatientService
    module GetHealthPublicInsurance
      # 患者情報の登録の結果を表現するクラス
      class Result < ::OrcaApi::PatientService::Result
        KEYS = Set.new(
          %w(
            Patient_Information
            HealthInsurance_Information
            PublicInsurance_Information
            HealthInsurance_Combination_Information
          )
        )

        def health_public_insurance
          @body.select { |k, _|
            KEYS.include?(k)
          } || {}
        end
      end
    end
  end
end
