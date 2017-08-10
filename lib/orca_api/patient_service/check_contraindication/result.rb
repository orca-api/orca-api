# coding: utf-8

module OrcaApi
  class PatientService < Service
    module CheckContraindication
      # 薬剤併用禁忌チェックの結果を表現するクラス
      class Result < ::OrcaApi::PatientService::Result
        json_attr_reader :Perform_Month, :Medical_Information, :Symptom_Information
      end
    end
  end
end
