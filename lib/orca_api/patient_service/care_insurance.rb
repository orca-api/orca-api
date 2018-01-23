require_relative "care_common"

module OrcaApi
  class PatientService < Service
    # 介護保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api6
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036_err.pdf
    class CareInsurance < CareCommon
    end
  end
end
