# frozen_string_literal: true

require_relative "service"

module OrcaApi
  # 症状詳記を扱うサービスを表現したクラス
  #
  # @see https://www.orca.med.or.jp/receipt/tec/api/subjectives.html
  class SubjectiveService < Service
    # 症状詳記APIの処理結果を表現したクラス
    class Result < ::OrcaApi::Result
      def ok?
        api_result =~ /\A(?:00|K[1234])\z/ ? true : false
      end

      def locked?
        api_result == "90"
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
  end
end
