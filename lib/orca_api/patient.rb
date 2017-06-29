# coding: utf-8

require_relative "api_struct"

module OrcaApi
  # 患者情報を表現するクラス
  class Patient < ApiStruct
    # 患者情報に含まれる自宅情報を表現するクラス
    class HomeAddressInformation < ApiStruct
      define_accessors(
        "Address_ZipCode" => "address_zip_code",
        "WholeAddress1" => "whole_address1",
        "WholeAddress2" => "whole_address2",
        "PhoneNumber1" => "phone_number1",
        "PhoneNumber2" => "phone_number2"
      )
    end

    # 患者情報に含まれる勤務先を表現するクラス
    class WorkPlaceInformation < ApiStruct
      define_accessors(
        "WholeName" => "whole_name",
        "Address_ZipCode" => "address_zip_code",
        "WholeAddress1" => "whole_address1",
        "WholeAddress2" => "whole_address2",
        "PhoneNumber" => "phone_number"
      )
    end

    # 患者情報に含まれる連絡先を表現するクラス
    class ContactInformation < ApiStruct
      define_accessors(
        "WholeName" => "whole_name",
        "Relationship" => "relationship",
        "Address_ZipCode" => "address_zip_code",
        "WholeAddress1" => "whole_address1",
        "WholeAddress2" => "whole_address2",
        "PhoneNumber1" => "phone_number1",
        "PhoneNumber2" => "phone_number2"
      )
    end

    # 患者情報に含まれる帰省先を表現するクラス
    class Home2Information < ApiStruct
      define_accessors(
        "WholeName" => "whole_name",
        "Address_ZipCode" => "address_zip_code",
        "WholeAddress1" => "whole_address1",
        "WholeAddress2" => "whole_address2",
        "PhoneNumber" => "phone_number"
      )
    end

    define_accessors(
      {
        "Patient_ID" => "patient_id",
        "WholeName" => "whole_name",
        "WholeName_inKana" => "whole_name_in_kana",
        "BirthDate" => "birth_date",
        "Sex" => "sex",
        "HouseHolder_WholeName" => "house_holder_whole_name",
        "Relationship" => "relationship",
        "Occupation" => "occupation",
        "NickName" => "nick_name",
        "CellularNumber" => "cellular_number",
        "FaxNumber" => "fax_number",
        "EmailAddress" => "email_address",
        "Home_Address_Information" => "home_address_information",
        "WorkPlace_Information" => "work_place_information",
        "Contact_Information" => "contact_information",
        "Home2_Information" => "home2_information",
        "Contraindication1" => "contraindication1",
        "Contraindication2" => "contraindication2",
        "Allergy1" => "allergy1",
        "Allergy2" => "allergy2",
        "Infection1" => "infection1",
        "Infection2" => "infection2",
        "Comment1" => "comment1",
        "Comment2" => "comment2",
        "TestPatient_Flag" => "test_patient_flag",
        "Death_Flag" => "death_flag",
        "Reduction_Reason" => "reduction_reason",
        "Reduction_Reason_Name" => "reduction_reason_name",
        "Discount" => "discount",
        "Discount_Name" => "discount_name",
        "Condition1" => "condition1",
        "Condition1_Name" => "condition1_name",
        "Condition2" => "condition2",
        "Condition2_Name" => "condition2_name",
        "Condition3" => "condition3",
        "Condition3_Name" => "condition3_name"
      },
      {
        "home_address_information" => HomeAddressInformation,
        "work_place_information" => WorkPlaceInformation,
        "contact_information" => ContactInformation,
        "home2_information" => Home2Information,
      }
    )
    alias_method("id", "patient_id")
    alias_method("id=", "patient_id=")
  end
end
