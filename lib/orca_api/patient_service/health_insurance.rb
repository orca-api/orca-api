require_relative "health_public_insurance_common"

module OrcaApi
  class PatientService < Service
    # 患者保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class HealthInsurance < HealthPublicInsuranceCommon
      private

      def insurance_information_name
        "HealthInsurance_Information"
      end
    end
  end
end
