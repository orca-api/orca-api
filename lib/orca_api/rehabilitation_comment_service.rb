require_relative "service"

module OrcaApi
  # リハビリコメント登録や取得を行うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api8
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v035.pdf
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v035_err.pdf
  class RehabilitationCommentService < Service
    # 該当患者のリハビリコメント一覧を取得する
    #
    # @params [String] patient_id
    #   患者番号
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    def list(patient_id)
      req = {
        "Request_Number" => "00",
        "Karte_Uid" => orca_api.karte_uid,
        "Patient_ID" => patient_id,
      }

      Result.new(orca_api.call("/api21/medicalmodv35", body: { "medicalv3req5" => req }))
    end

    # 該当患者のリハビリコメント詳細情報を取得する
    #
    # @params [String] patient_id
    #   患者番号
    # @params [String] medication_code
    #   診療コード
    # @params [String] perform_date
    #   診療年月
    # @params [String] insurance_combination_number
    #   保険組合せ
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    def get(patient_id, medication_code, perform_date, insurance_combination_number)
      req = {
        "Request_Number" => "00",
        "Karte_Uid" => orca_api.karte_uid,
        "Patient_ID" => patient_id,
        "Perform_Information" => {
          "Medication_Code" => medication_code,
          "Perform_Date" => perform_date,
          "Insurance_Combination_Number" => insurance_combination_number,
        },
      }

      Result.new(orca_api.call("/api21/medicalmodv35", body: { "medicalv3req5" => req }))
    end
  end
end
