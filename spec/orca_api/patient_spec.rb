# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::Patient do
  describe ".new" do
    subject { OrcaApi::Patient.new(attributes) }

    describe "日レセAPIのレスポンスから生成する" do
      let(:attributes) {
        {
          "Patient_ID" => "00001",
          "WholeName" => "テスト　カンジャ",
          "WholeName_inKana" => "テスト　カンジャ",
          "BirthDate" => "1965-04-04",
          "Sex" => "1",
          "HouseHolder_WholeName" => "テスト　カンジャ",
          "Relationship" => "世帯主",
          "Occupation" => "警備員",
          "NickName" => "ニックネーム",
          "CellularNumber" => "012-3456-7890",
          "FaxNumber" => "01-2345-6789",
          "EmailAddress" => "test@example.com",
          # 自宅情報
          "Home_Address_Information" => {
            "Address_ZipCode" => "6900051",
            "WholeAddress1" => "島根県松江市横浜町",
            "WholeAddress2" => "１１５５",
            "PhoneNumber1" => "0852-22-2222",
            "PhoneNumber2" => "0852-44-4444"
          },
          # 勤務先
          "WorkPlace_Information" => {
            "WholeName" => "島根銀行株式会社",
            "Address_ZipCode" => "6900015",
            "WholeAddress1" => "島根県松江市上乃木",
            "WholeAddress2" => "１２３４５６",
            "PhoneNumber" => "0852-33-3333"
          },
          # 連絡先
          "Contact_Information" => {
            "WholeName" => "島根銀行株式会社",
            "Relationship" => "勤務先",
            "Address_ZipCode" => "6900015",
            "WholeAddress1" => "島根県松江市上乃木",
            "WholeAddress2" => "１２３４５６",
            "PhoneNumber1" => "0852-33-3333",
            "PhoneNumber2" => "0852-55-5555"
          },
          # 帰省先
          "Home2_Information" => {
            "WholeName" => "実家",
            "Address_ZipCode" => "6900099",
            "WholeAddress1" => "島根県松江市沖縄町",
            "WholeAddress2" => "５５１１",
            "PhoneNumber" => "0852-99-9999"
          },
          "Contraindication1" => "　",
          "Contraindication2" => "　",
          "Allergy1" => "えび",
          "Allergy2" => "かに",
          "Infection1" => "",
          "Infection2" => "",
          "Comment1" => "",
          "Comment2" => "",
          "TestPatient_Flag" => "0",
          "Death_Flag" => "0",
          "Reduction_Reason" => "00",
          "Reduction_Reason_Name" => "該当なし",
          "Discount" => "00",
          "Discount_Name" => "該当なし",
          "Condition1" => "00",
          "Condition1_Name" => "該当なし",
          "Condition2" => "00",
          "Condition2_Name" => "該当なし",
          "Condition3" => "00",
          "Condition3_Name" => "該当なし",
        }
      }

      OrcaApi::Patient.attribute_mappings.each do |json_name, attr_name|
        if OrcaApi::Patient.struct_mappings.key?(attr_name)
          klass = OrcaApi::Patient.struct_mappings[attr_name]
          describe attr_name do
            subject { super().send(attr_name) }

            it { is_expected.to be_instance_of(klass) }

            klass.attribute_mappings.each do |struct_json_name, struct_attr_name|
              its(struct_attr_name) { is_expected.to eq(attributes[json_name][struct_json_name]) }
            end
          end
        else
          its(attr_name) { is_expected.to eq(attributes[json_name]) }
        end
      end
    end

    describe "属性名を文字列で指定した属性値から生成する" do
      let(:attributes) {
        {
          "patient_id" => "00001",
          "whole_name" => "テスト　カンジャ",
          "whole_name_in_kana" => "テスト　カンジャ",
          "birth_date" => "1965-04-04",
          "sex" => "1",
          "house_holder_whole_name" => "テスト　カンジャ",
          "relationship" => "世帯主",
          "occupation" => "警備員",
          "nick_name" => "ニックネーム",
          "cellular_number" => "012-3456-7890",
          "fax_number" => "01-2345-6789",
          "email_address" => "test@example.com",
          # 自宅情報
          "home_address_information" => {
            "address_zip_code" => "6900051",
            "whole_address1" => "島根県松江市横浜町",
            "whole_address2" => "１１５５",
            "phone_number1" => "0852-22-2222",
            "phone_number2" => "0852-44-4444"
          },
          # 勤務先
          "work_place_information" => {
            "whole_name" => "島根銀行株式会社",
            "address_zip_code" => "6900015",
            "whole_address1" => "島根県松江市上乃木",
            "whole_address2" => "１２３４５６",
            "phone_number" => "0852-33-3333"
          },
          # 連絡先
          "contact_information" => {
            "whole_name" => "島根銀行株式会社",
            "relationship" => "勤務先",
            "address_zip_code" => "6900015",
            "whole_address1" => "島根県松江市上乃木",
            "whole_address2" => "１２３４５６",
            "phone_number1" => "0852-33-3333",
            "phone_number2" => "0852-55-5555"
          },
          # 帰省先
          "home2_information" => {
            "whole_name" => "実家",
            "address_zip_code" => "6900099",
            "whole_address1" => "島根県松江市沖縄町",
            "whole_address2" => "５５１１",
            "phone_number" => "0852-99-9999"
          },
          "contraindication1" => "　",
          "contraindication2" => "　",
          "allergy1" => "えび",
          "allergy2" => "かに",
          "infection1" => "",
          "infection2" => "",
          "comment1" => "",
          "comment2" => "",
          "test_patient_flag" => "0",
          "death_flag" => "0",
          "reduction_reason" => "00",
          "reduction_reason_name" => "該当なし",
          "discount" => "00",
          "discount_name" => "該当なし",
          "condition1" => "00",
          "condition1_name" => "該当なし",
          "condition2" => "00",
          "condition2_name" => "該当なし",
          "condition3" => "00",
          "condition3_name" => "該当なし",
        }
      }

      OrcaApi::Patient.attribute_mappings.each do |_, attr_name|
        if OrcaApi::Patient.struct_mappings.key?(attr_name)
          klass = OrcaApi::Patient.struct_mappings[attr_name]
          describe attr_name do
            subject { super().send(attr_name) }

            it { is_expected.to be_instance_of(klass) }

            klass.attribute_mappings.each do |_, struct_attr_name|
              its(struct_attr_name) { is_expected.to eq(attributes[attr_name][struct_attr_name]) }
            end
          end
        else
          its(attr_name) { is_expected.to eq(attributes[attr_name]) }
        end
      end
    end

    describe "属性名をシンボルで指定した属性値から生成する" do
      let(:attributes) {
        {
          patient_id: "00001",
          whole_name: "テスト　カンジャ",
          whole_name_in_kana: "テスト　カンジャ",
          birth_date: "1965-04-04",
          sex: "1",
          house_holder_whole_name: "テスト　カンジャ",
          relationship: "世帯主",
          occupation: "警備員",
          nick_name: "ニックネーム",
          cellular_number: "012-3456-7890",
          fax_number: "01-2345-6789",
          email_address: "test@example.com",
          # 自宅情報
          home_address_information: {
            address_zip_code: "6900051",
            whole_address1: "島根県松江市横浜町",
            whole_address2: "１１５５",
            phone_number1: "0852-22-2222",
            phone_number2: "0852-44-4444"
          },
          # 勤務先
          work_place_information: {
            whole_name: "島根銀行株式会社",
            address_zip_code: "6900015",
            whole_address1: "島根県松江市上乃木",
            whole_address2: "１２３４５６",
            phone_number: "0852-33-3333"
          },
          # 連絡先
          contact_information: {
            whole_name: "島根銀行株式会社",
            relationship: "勤務先",
            address_zip_code: "6900015",
            whole_address1: "島根県松江市上乃木",
            whole_address2: "１２３４５６",
            phone_number1: "0852-33-3333",
            phone_number2: "0852-55-5555"
          },
          # 帰省先
          home2_information: {
            whole_name: "実家",
            address_zip_code: "6900099",
            whole_address1: "島根県松江市沖縄町",
            whole_address2: "５５１１",
            phone_number: "0852-99-9999"
          },
          contraindication1: "　",
          contraindication2: "　",
          allergy1: "えび",
          allergy2: "かに",
          infection1: "",
          infection2: "",
          comment1: "",
          comment2: "",
          test_patient_flag: "0",
          death_flag: "0",
          reduction_reason: "00",
          reduction_reason_name: "該当なし",
          discount: "00",
          discount_name: "該当なし",
          condition1: "00",
          condition1_name: "該当なし",
          condition2: "00",
          condition2_name: "該当なし",
          condition3: "00",
          condition3_name: "該当なし",
        }
      }

      OrcaApi::Patient.attribute_mappings.each do |_, attr_name|
        if OrcaApi::Patient.struct_mappings.key?(attr_name)
          klass = OrcaApi::Patient.struct_mappings[attr_name]
          describe attr_name do
            subject { super().send(attr_name) }

            it { is_expected.to be_instance_of(klass) }

            klass.attribute_mappings.each do |_, struct_attr_name|
              its(struct_attr_name) { is_expected.to eq(attributes[attr_name.to_sym][struct_attr_name.to_sym]) }
            end
          end
        else
          its(attr_name) { is_expected.to eq(attributes[attr_name.to_sym]) }
        end
      end
    end
  end
end
