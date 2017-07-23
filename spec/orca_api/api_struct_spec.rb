# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::ApiStruct do
  class MyApiStruct < OrcaApi::ApiStruct
    class EmptyStruct < OrcaApi::ApiStruct
      define_accessors(["ID"])
    end

    define_accessors(
      [
        "Patient_ID",
        "WholeName",
        "WholeName_inKana",
        "Sex",
        ["Home_Address_Information", { struct: OrcaApi::PatientInformation::HomeAddressInformation }],
        ["WorkPlace_Information", { struct: OrcaApi::PatientInformation::WorkPlaceInformation }],
        ["HealthInsurance_Info", { struct: OrcaApi::HealthPublicInsurance::HealthInsuranceInfo, array: true }],
        ["PublicInsurance_Info", { struct: OrcaApi::HealthPublicInsurance::PublicInsuranceInfo, array: true }],
        ["Empty_Struct", { struct: EmptyStruct }],
        ["Array1", { array: true }],
        ["Array2", { array: true }],
        ["Array3", { array: true }],
      ]
    )
  end

  let(:attributes) {
    {
      "Patient_ID" => "1",
      "WholeName" => "テスト　患者",
      "Sex" => nil,
      "Home_Address_Information" => {
        "Address_ZipCode" => "6900051",
        "WholeAddress1" => "島根県松江市横浜町",
        "WholeAddress2" => "１１５５",
      },
      "HealthInsurance_Info" => [
        {},
        {},
      ],
      "PublicInsurance_Info" => [
        {
          "PublicInsurance_Id" => "0000000004",
        },
        {},
        {
          "PublicInsurance_Id" => "0000000006",
        },
        {},
        {},
      ],
      "Empty_Struct" => {},
      "Array1" => [],
      "Array2" => ["01", nil, "03", nil, nil],
      "Array3" => nil,
    }
  }
  let(:my_api_struct) { MyApiStruct.new(attributes) }

  shared_examples "属性とその値が正しいこと" do
    its(:patient_id) { is_expected.to eq("1") }
    its(:whole_name) { is_expected.to eq("テスト　患者") }
    its(:whole_name_in_kana) { is_expected.to eq(nil) }

    describe "home_address_information" do
      subject { super().send("home_address_information") }

      its(:address_zip_code) { is_expected.to eq("6900051") }
      its(:whole_address1) { is_expected.to eq("島根県松江市横浜町") }
      its(:whole_address2) { is_expected.to eq("１１５５") }
      its(:phone_number1) { is_expected.to be_nil }
      its(:phone_number2) { is_expected.to be_nil }
    end

    its(:work_place_information) { is_expected.to be_nil }

    describe "public_insurance_info" do
      subject { super().send("public_insurance_info") }

      its(:length) { is_expected.to eq(5) }

      describe "[0]" do
        subject { super()[0] }

        it { is_expected.to be_instance_of(OrcaApi::HealthPublicInsurance::PublicInsuranceInfo) }

        its(:public_insurance_id) { is_expected.to eq("0000000004") }
      end

      describe "[2]" do
        subject { super()[2] }

        its(:public_insurance_id) { is_expected.to eq("0000000006") }
      end

      [1, 3, 4].each do |index|
        describe "[#{index}]" do
          subject { super()[index] }

          it { is_expected.to be_instance_of(OrcaApi::HealthPublicInsurance::PublicInsuranceInfo) }

          its(:public_insurance_id) { is_expected.to be_nil }
        end
      end
    end
  end

  describe "#new" do
    subject { my_api_struct }

    include_examples "属性とその値が正しいこと"
  end

  describe "#update" do
    subject { MyApiStruct.new({}).update(attributes) }

    it { is_expected.to be_instance_of(MyApiStruct) }
    include_examples "属性とその値が正しいこと"
  end

  describe "#attributes" do
    shared_examples "結果が正しいこと" do |*args|
      subject { my_api_struct.attributes(*args) }

      it { is_expected.to eq(expected) }
    end

    context "name_type: :string, omit: true" do
      let(:expected) {
        {
          "patient_id" => "1",
          "whole_name" => "テスト　患者",
          "array2" => [
            "01",
            "",
            "03",
          ],
          "home_address_information" => {
            "address_zip_code" => "6900051",
            "whole_address1" => "島根県松江市横浜町",
            "whole_address2" => "１１５５",
          },
          "public_insurance_info" => [
            {
              "public_insurance_id" => "0000000004",
            },
            {},
            {
              "public_insurance_id" => "0000000006",
            },
          ]
        }
      }

      include_examples "結果が正しいこと", name_type: :string, omit: true

      describe "name_typeを省略した場合は、name_type: stringと同じ" do
        include_examples "結果が正しいこと", omit: true
      end
    end

    context "name_type: :symbol, omit: true" do
      let(:expected) {
        {
          patient_id: "1",
          whole_name: "テスト　患者",
          array2: [
            "01",
            "",
            "03",
          ],
          home_address_information: {
            address_zip_code: "6900051",
            whole_address1: "島根県松江市横浜町",
            whole_address2: "１１５５",
          },
          public_insurance_info: [
            {
              public_insurance_id: "0000000004",
            },
            {},
            {
              public_insurance_id: "0000000006",
            },
          ]
        }
      }

      include_examples "結果が正しいこと", name_type: :symbol, omit: true
    end

    context "name_type: :json, omit: true" do
      let(:expected) {
        {
          "Patient_ID" => "1",
          "WholeName" => "テスト　患者",
          "Array2" => [
            "01",
            "",
            "03",
          ],
          "Home_Address_Information" => {
            "Address_ZipCode" => "6900051",
            "WholeAddress1" => "島根県松江市横浜町",
            "WholeAddress2" => "１１５５",
          },
          "PublicInsurance_Info" => [
            {
              "PublicInsurance_Id" => "0000000004",
            },
            {},
            {
              "PublicInsurance_Id" => "0000000006",
            },
          ]
        }
      }

      include_examples "結果が正しいこと", name_type: :json, omit: true
    end

    context "name_type: nil, omit: false" do
      let(:expected) {
        {
          "patient_id" => "1",
          "whole_name" => "テスト　患者",
          "whole_name_in_kana" => "",
          "sex" => "",
          "home_address_information" => {
            "address_zip_code" => "6900051",
            "whole_address1" => "島根県松江市横浜町",
            "whole_address2" => "１１５５",
            "phone_number1" => "",
            "phone_number2" => "",
          },
          "work_place_information" => {
            "whole_name" => "",
            "address_zip_code" => "",
            "whole_address1" => "",
            "whole_address2" => "",
            "phone_number" => "",
          },
          "array1" => [],
          "array2" => [
            "01",
            "",
            "03",
            "",
            "",
          ],
          "array3" => [],
          "empty_struct" => {
            "id" => "",
          },
          "health_insurance_info" => [
            {
              "insurance_provider_mode" => "",
              "insurance_provider_id" => "",
              "insurance_provider_class" => "",
              "insurance_provider_number" => "",
              "insurance_provider_whole_name" => "",
              "health_insured_person_symbol" => "",
              "health_insured_person_number" => "",
              "health_insured_person_continuation" => "",
              "health_insured_person_assistance" => "",
              "health_insured_person_assistance_name" => "",
              "relation_to_insured_person" => "",
              "health_insured_person_whole_name" => "",
              "certificate_start_date" => "",
              "certificate_expired_date" => "",
              "certificate_get_date" => "",
              "certificate_check_date" => "",
            },
            {
              "insurance_provider_mode" => "",
              "insurance_provider_id" => "",
              "insurance_provider_class" => "",
              "insurance_provider_number" => "",
              "insurance_provider_whole_name" => "",
              "health_insured_person_symbol" => "",
              "health_insured_person_number" => "",
              "health_insured_person_continuation" => "",
              "health_insured_person_assistance" => "",
              "health_insured_person_assistance_name" => "",
              "relation_to_insured_person" => "",
              "health_insured_person_whole_name" => "",
              "certificate_start_date" => "",
              "certificate_expired_date" => "",
              "certificate_get_date" => "",
              "certificate_check_date" => "",
            },
          ],
          "public_insurance_info" => [
            {
              "public_insurance_mode" => "",
              "public_insurance_id" => "0000000004",
              "public_insurance_class" => "",
              "public_insurance_name" => "",
              "public_insurer_number" => "",
              "public_insured_person_number" => "",
              "certificate_issued_date" => "",
              "certificate_expired_date" => "",
              "certificate_check_date" => "",
              "rate_admission" => "",
              "money_admission" => "",
              "rate_outpatient" => "",
              "money_outpatient" => "",
            },
            {
              "public_insurance_mode" => "",
              "public_insurance_id" => "",
              "public_insurance_class" => "",
              "public_insurance_name" => "",
              "public_insurer_number" => "",
              "public_insured_person_number" => "",
              "certificate_issued_date" => "",
              "certificate_expired_date" => "",
              "certificate_check_date" => "",
              "rate_admission" => "",
              "money_admission" => "",
              "rate_outpatient" => "",
              "money_outpatient" => "",
            },
            {
              "public_insurance_mode" => "",
              "public_insurance_id" => "0000000006",
              "public_insurance_class" => "",
              "public_insurance_name" => "",
              "public_insurer_number" => "",
              "public_insured_person_number" => "",
              "certificate_issued_date" => "",
              "certificate_expired_date" => "",
              "certificate_check_date" => "",
              "rate_admission" => "",
              "money_admission" => "",
              "rate_outpatient" => "",
              "money_outpatient" => "",
            },
            {
              "public_insurance_mode" => "",
              "public_insurance_id" => "",
              "public_insurance_class" => "",
              "public_insurance_name" => "",
              "public_insurer_number" => "",
              "public_insured_person_number" => "",
              "certificate_issued_date" => "",
              "certificate_expired_date" => "",
              "certificate_check_date" => "",
              "rate_admission" => "",
              "money_admission" => "",
              "rate_outpatient" => "",
              "money_outpatient" => "",
            },
            {
              "public_insurance_mode" => "",
              "public_insurance_id" => "",
              "public_insurance_class" => "",
              "public_insurance_name" => "",
              "public_insurer_number" => "",
              "public_insured_person_number" => "",
              "certificate_issued_date" => "",
              "certificate_expired_date" => "",
              "certificate_check_date" => "",
              "rate_admission" => "",
              "money_admission" => "",
              "rate_outpatient" => "",
              "money_outpatient" => "",
            },
          ]
        }
      }

      include_examples "結果が正しいこと", name_type: nil, omit: false
    end

    describe "include_filterで特定の属性のみを取得する" do
      shared_examples "フィルタリングした結果が正しいこと" do
        subject {
          my_api_struct.attributes(omit: true, &include_filter)
        }

        it { is_expected.to eq(expected) }
      end

      describe "すべての属性を取得する" do
        let(:include_filter) { ->(*_) { true } }
        let(:expected) {
          {
            "patient_id" => "1",
            "whole_name" => "テスト　患者",
            "array2" => [
              "01",
              "",
              "03",
            ],
            "home_address_information" => {
              "address_zip_code" => "6900051",
              "whole_address1" => "島根県松江市横浜町",
              "whole_address2" => "１１５５",
            },
            "public_insurance_info" => [
              {
                "public_insurance_id" => "0000000004",
              },
              {},
              {
                "public_insurance_id" => "0000000006",
              },
            ]
          }
        }

        include_examples "フィルタリングした結果が正しいこと"
      end

      describe "すべての属性を取得しない" do
        let(:include_filter) { ->(*_) { false } }
        let(:expected) {
          {}
        }

        include_examples "フィルタリングした結果が正しいこと"
      end

      describe "一部の属性のみを取得する" do
        let(:include_filter) {
          settings = {
            MyApiStruct => %w(Patient_ID Home_Address_Information WorkPlace_Information),
            OrcaApi::PatientInformation::HomeAddressInformation => %w(Address_ZipCode WholeAddress2 PhoneNumber2),
          }
          ->(api_struct, json_name, _) { settings.key?(api_struct.class) && settings[api_struct.class].include?(json_name) }
        }
        let(:expected) {
          {
            "patient_id" => "1",
            "home_address_information" => {
              "address_zip_code" => "6900051",
              "whole_address2" => "１１５５",
            },
          }
        }

        include_examples "フィルタリングした結果が正しいこと"
      end
    end
  end
end
