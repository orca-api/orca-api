# frozen_string_literal: true

require_relative "service"
require_relative "ext/hash_slice"

module OrcaApi
  # 症状詳記を扱うサービスを表現したクラス
  #
  # @see https://www.orca.med.or.jp/receipt/tec/api/subjectives.html
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19548#api2
  class SubjectiveService < Service
    using Ext::HashSlice if Ext::HashSlice.need_using?

    # 症状詳記APIの処理結果を表現したクラス
    class Result < ::OrcaApi::Result
      def ok?
        api_result =~ /\A(?:0+|K[1234]|WK[123])\z/ ? true : false
      end

      def locked?
        super || api_result == "90"
      end
    end

    CREATE_PARAMS = [
      "InOut",
      "Patient_ID",
      "Perform_Date",
      "Department_Code",
      "Insurance_Combination_Number",
      "Subjectives_Detail_Record",
      "Subjectives_Code",
      "HealthInsurance_Information" => [
        "InsuranceProvider_Class",
        "InsuranceProvider_WholeName",
        "InsuranceProvider_Number",
        "HealthInsuredPerson_Symbol",
        "HealthInsuredPerson_Number",
        "HealthInsuredPerson_Continuation",
        "HealthInsuredPerson_Assistance",
        "RelationToInsuredPerson",
        "HealthInsuredPerson_WholeName",
        "Certificate_StartDate",
        "Certificate_ExpiredDate",
        "PublicInsurance_Information" => [
          "PublicInsurance_Class",
          "PublicInsurance_Name",
          "PublicInsurer_Number",
          "PublicInsuredPerson_Number",
          "Certificate_IssuedDate",
          "Certificate_ExpiredDate"
        ].freeze
      ].freeze
    ].freeze
    private_constant :CREATE_PARAMS

    DESTROY_PARAMS = CREATE_PARAMS
    private_constant :DESTROY_PARAMS

    LIST_PARAMS = [
      "InOut",
      "Patient_ID",
      "Perform_Date",
      "Department_Code",
      "Insurance_Combination_Number",
      "Perform_Day",
      "Subjectives_Detail_Record",
      "Subjectives_Number"
    ].freeze
    private_constant :LIST_PARAMS

    # 症状詳記登録
    def create(params)
      Result.new(
        orca_api.call(
          "/orca25/subjectivesv2",
          params: { "class" => "01" },
          body: { "subjectivesmodreq" => shaper(params, CREATE_PARAMS) }
        )
      )
    end

    # 症状詳記削除
    def destroy(params)
      Result.new(
        orca_api.call(
          "/orca25/subjectivesv2",
          params: { "class" => "02" },
          body: { "subjectivesmodreq" => shaper(params, DESTROY_PARAMS) }
        )
      )
    end

    # 症状詳記取得
    def list(params)
      result = call_01 params
      return result unless result.ok?

      result.subjectives_information.each do |info|
        sub_result = call_02(result.patient_information["Patient_ID"], result.perform_date, info)
        if sub_result.ok?
          info["Subjectives_Code"] = sub_result.subjectives_code_information["Subjectives_Code"]
        end
      end
      result
    end

    private

    def shaper(target, schema)
      u, c = schema.partition { |e| e.is_a? Hash }
      target.slice(*c).merge(
        u.reduce({}) { |r, e| r.merge e }.map { |key, val|
          shaped = shaper(Hash(target[key]), val)
          shaped.empty? ? nil : [key, shaped]
        }.compact.to_h
      )
    end

    def call_01(params)
      Result.new(
        orca_api.call(
          "/api01rv2/subjectiveslstv2",
          body: {
            "subjectiveslstreq" => {
              "Request_Number" => "01"
            }.merge(shaper(params, LIST_PARAMS))
          }
        )
      )
    end

    def call_02(patient_id, perform_date, info)
      Result.new(
        orca_api.call(
          "/api01rv2/subjectiveslstv2",
          body: {
            "subjectiveslstreq" => {
              "Request_Number" => "02",
              "InOut" => info["InOut"],
              "Patient_ID" => patient_id,
              "Perform_Date" => perform_date,
              "Department_Code" => info["Department_Code"],
              "Insurance_Combination_Number" => info["HealthInsurance_Information"]["Insurance_Combination_Number"],
              "Subjectives_Detail_Record" => info["Subjectives_Detail_Record"],
              "Subjectives_Number" => info["Subjectives_Number"]
            }
          }
        )
      )
    end
  end
end
