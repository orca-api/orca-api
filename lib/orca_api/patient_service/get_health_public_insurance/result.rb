# coding: utf-8

module OrcaApi
  class PatientService < Service
    module GetHealthPublicInsurance
      # 患者保険・公費情報の取得の結果を表現するクラス
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
