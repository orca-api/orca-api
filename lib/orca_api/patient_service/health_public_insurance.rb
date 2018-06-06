# frozen_string_literal: true

require_relative "health_public_insurance_common"

module OrcaApi
  class PatientService < Service
    # 患者保険・公費情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class HealthPublicInsurance < HealthPublicInsuranceCommon
      OPTION_KEYS = %w[
        HealthInsurance_Information
        PublicInsurance_Information
        Patient_Select_Information
      ].freeze
      private_constant :OPTION_KEYS

      # 患者保険・公費情報を更新する
      #
      # @param [String] id
      #   患者ID
      # @param [Hash] args
      #   患者保険情報パラメータ
      #   * "HealthInsurance_Information" (Hash)
      #     患者保険情報
      #   * "PublicInsurance_Information" (Hash)
      #     患者公費情報
      #   * "Patient_Select_Information" (Array[Hash])
      #     確認メッセージ
      #
      # @see HealthPublicInsuranceCommon#update
      def update(id, args)
        super(
          id,
          args.select { |key, _| OPTION_KEYS.include? key }
        )
      end

      private

      def copy_attribute_names
        ["HealthInsurance_Information", "PublicInsurance_Information"]
      end
    end
  end
end
