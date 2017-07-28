# coding: utf-8

require_relative "service"
require_relative "patient_service/result"
require_relative "patient_service/get"
require_relative "patient_service/get_health_public_insurance"
require_relative "patient_service/create"
require_relative "patient_service/update"
require_relative "patient_service/update_health_public_insurance"

module OrcaApi
  # 患者情報を扱うサービスを表現したクラス
  class PatientService < Service
    include Get
    include GetHealthPublicInsurance
    include Create
    include Update
    include UpdateHealthPublicInsurance

    private

    def unlock(api_path, body)
      res0 = orca_api.call(api_path, body: body)
      res = res0.first[1]
      if /0+/ !~ res["Response_Number"]
        # TODO: エラー処理
      end
    end
  end
end
