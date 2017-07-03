# coding: utf-8

require_relative "api_struct"
require_relative "patient_information"

module OrcaApi
  # 患者保険・公費情報を表現するクラス
  class HealthPublicInsurance < ApiStruct
    define_accessors(
      {
        "Patient_Information" => "patient_information",
        "HealthInsurance_Information" => "health_insurance",
        "PublicInsurance_Information" => "public_insurance_information",
        "HealthInsurance_Combination_Information" => "health_insurance_combination",
      },
      {
        "patient_information" => PatientInformation,
      }
    )
  end
end
