# coding: utf-8

require_relative "api_struct"
require_relative "patient_information"

module OrcaApi
  # 患者保険・公費情報を表現するクラス
  class HealthPublicInsurance < ApiStruct
    # 患者保険情報に含まれる個別の患者保険情報を表現するクラス
    class HealthInsuranceInfo < ApiStruct
      define_accessors(
        %w(
          InsuranceProvider_Mode
          InsuranceProvider_Id
          InsuranceProvider_Class
          InsuranceProvider_Number
          InsuranceProvider_WholeName
          HealthInsuredPerson_Symbol
          HealthInsuredPerson_Number
          HealthInsuredPerson_Continuation
          HealthInsuredPerson_Assistance
          HealthInsuredPerson_Assistance_Name
          RelationToInsuredPerson
          HealthInsuredPerson_WholeName
          Certificate_StartDate
          Certificate_ExpiredDate
          Certificate_GetDate
          Certificate_CheckDate
        )
      )
    end

    # 患者保険・公費情報に含まれる患者保険情報を表現するクラス
    class HealthInsuranceInformation < ApiStruct
      define_accessors(
        [
          ["HealthInsurance_Info", { struct: HealthInsuranceInfo, array: true }],
        ]
      )
    end

    # 公費情報に含まれる個別の公費情報を表現するクラス
    class PublicInsuranceInfo < ApiStruct
      define_accessors(
        %w(
          PublicInsurance_Mode
          PublicInsurance_Id
          PublicInsurance_Class
          PublicInsurance_Name
          PublicInsurer_Number
          PublicInsuredPerson_Number
          Certificate_IssuedDate
          Certificate_ExpiredDate
          Certificate_CheckDate

          Rate_Admission
          Money_Admission
          Rate_Outpatient
          Money_Outpatient
        )
      )
    end

    # 患者保険・公費情報に含まれる公費情報を表現するクラス
    class PublicInsuranceInformation < ApiStruct
      define_accessors(
        [
          ["PublicInsurance_Info", { struct: PublicInsuranceInfo, array: true }],
        ]
      )
    end

    # 保険組合せ情報に含まれる個別の保険組合せ情報を表現するクラス
    class HealthInsuranceCombinationInfo < ApiStruct
      define_accessors(
        [
          "Insurance_Combination_Mode",
          "Insurance_Combination_Number",
          "Insurance_Combination_Rate_Admission",
          "Insurance_Combination_Rate_Outpatient",
          "Insurance_Combination_StartDate",
          "Insurance_Combination_ExpiredDate",
          "InsuranceProvider_Id",
          "InsuranceProvider_Class",
          "InsuranceProvider_Number",
          "InsuranceProvider_WholeName",
          "HealthInsuredPerson_Symbol",
          "HealthInsuredPerson_Number",
          "HealthInsuredPerson_Continuation",
          "HealthInsuredPerson_Assistance",
          "HealthInsuredPerson_Assistance_Name",
          "RelationToInsuredPerson",
          ["PublicInsurance_Info", { struct: PublicInsuranceInfo, array: true }],
        ]
      )
    end

    # 患者保険・公費情報に含まれる保険組合せ情報を表現するクラス
    class HealthInsuranceCombinationInformation < ApiStruct
      define_accessors(
        [
          ["HealthInsurance_Combination_Info", { struct: HealthInsuranceCombinationInfo, array: true }],
        ]
      )
    end

    define_accessors(
      [
        ["Patient_Information", { struct: PatientInformation }],
        ["HealthInsurance_Information", { struct: HealthInsuranceInformation }],
        ["PublicInsurance_Information", { struct: PublicInsuranceInformation }],
        ["HealthInsurance_Combination_Information", { struct: HealthInsuranceCombinationInformation }],
      ]
    )
  end
end
