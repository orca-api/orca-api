# coding: utf-8

require_relative "check_contraindication/result"

module OrcaApi
  class PatientService < Service
    # 薬剤併用禁忌チェック
    module CheckContraindication
      def check_contraindication(id, params)
        body = {
          "contraindication_checkreq" => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => id.to_s,
          }.merge(params),
        }
        Result.new(orca_api.call("/api01rv2/contraindicationcheckv2", body: body))
      end
    end
  end
end
