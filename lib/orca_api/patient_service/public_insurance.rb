# frozen_string_literal: true

require_relative "health_public_insurance_common"

module OrcaApi
  class PatientService < Service
    # 患者公費情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class PublicInsurance < HealthPublicInsuranceCommon
      def update(id, args)
        super(
          id,
          {
            "PublicInsurance_Information" => {
              "PublicInsurance_Info" => Array(args["PublicInsurance_Info"])
            },
            "Patient_Select_Information" => Array(args["Patient_Select_Information"])
          }
        )
      end

      private

      def copy_attribute_names
        ["PublicInsurance_Information"]
      end
    end
  end
end
