# coding: utf-8

require_relative "api_struct"

module OrcaApi
  # 患者情報を表現するクラス
  class PatientInformation < ApiStruct
    # 患者情報に含まれる自宅情報を表現するクラス
    class HomeAddressInformation < ApiStruct
      define_accessors(
        %w(
          Address_ZipCode
          WholeAddress1
          WholeAddress2
          PhoneNumber1
          PhoneNumber2
        )
      )
    end

    # 患者情報に含まれる勤務先を表現するクラス
    class WorkPlaceInformation < ApiStruct
      define_accessors(
        %w(
          WholeName
          Address_ZipCode
          WholeAddress1
          WholeAddress2
          PhoneNumber
        )
      )
    end

    # 患者情報に含まれる連絡先を表現するクラス
    class ContactInformation < ApiStruct
      define_accessors(
        %w(
          WholeName
          Relationship
          Address_ZipCode
          WholeAddress1
          WholeAddress2
          PhoneNumber1
          PhoneNumber2
        )
      )
    end

    # 患者情報に含まれる帰省先を表現するクラス
    class Home2Information < ApiStruct
      define_accessors(
        %w(
          WholeName
          Address_ZipCode
          WholeAddress1
          WholeAddress2
          PhoneNumber
        )
      )
    end

    define_accessors(
      [
        "Patient_ID",
        "WholeName",
        "WholeName_inKana",
        "BirthDate",
        "Sex",
        "HouseHolder_WholeName",
        "Relationship",
        "Occupation",
        "NickName",
        "CellularNumber",
        "FaxNumber",
        "EmailAddress",
        ["Home_Address_Information", { struct: HomeAddressInformation }],
        ["WorkPlace_Information", { struct: WorkPlaceInformation }],
        ["Contact_Information", { struct: ContactInformation }],
        ["Home2_Information", { struct: Home2Information }],
        "Contraindication1",
        "Contraindication2",
        "Allergy1",
        "Allergy2",
        "Infection1",
        "Infection2",
        "Comment1",
        "Comment2",
        "TestPatient_Flag",
        "Death_Flag",
        "Reduction_Reason",
        "Reduction_Reason_Name",
        "Discount",
        "Discount_Name",
        "Condition1",
        "Condition1_Name",
        "Condition2",
        "Condition2_Name",
        "Condition3",
        "Condition3_Name",
      ]
    )
    alias_method("id", "patient_id")
    alias_method("id=", "patient_id=")
  end
end
