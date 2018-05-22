# frozen_string_literal: true

require_relative "health_public_insurance_common"

module OrcaApi
  class PatientService < Service
    # 患者保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class HealthInsurance < HealthPublicInsuranceCommon
      def update(id, args)
        super(
          id,
          {
            "HealthInsurance_Information" => {
              "HealthInsurance_Info" => Array(args["HealthInsurance_Info"])
            },
            "Patient_Select_Information" => Array(args["Patient_Select_Information"])
          }
        )
      end

      private

      def copy_attribute_names
        ["HealthInsurance_Information"]
      end
    end
  end
end
