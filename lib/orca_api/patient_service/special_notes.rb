require_relative "income_common"

module OrcaApi
  class PatientService < Service
    # 特記事項を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v034.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v034_err.pdf
    class SpecialNotes < IncomeCommon
    end
  end
end
