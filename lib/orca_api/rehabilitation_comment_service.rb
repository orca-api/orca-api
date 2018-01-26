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
    # @param [String] patient_id
    #   患者番号
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    def list(patient_id)
      req = {
        "Request_Number" => "00",
        "Karte_Uid" => orca_api.karte_uid,
        "Patient_ID" => patient_id,
      }
      call(req)
    end

    # 該当患者のリハビリコメント詳細情報を取得する
    #
    # @param [String] patient_id
    #   患者番号
    # @param [String] medication_code
    #   診療コード
    # @param [String] perform_date
    #   診療年月
    # @param [String] insurance_combination_number
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
      call(req)
    end

    # 該当患者のリハビリコメントを修正する
    #
    # @param [String] patient_id
    #   患者番号
    # @param [Hash] args
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    def update(patient_id, args)
      req = {
        "Request_Number" => "01",
        "Karte_Uid" => orca_api.karte_uid,
        "Patient_ID" => patient_id.to_s,
      }
      locked_result = res = call(req)
      if !res.ok?
        return res
      end

      req.merge!(args)
      req["Request_Number"] = res.response_number
      req["Orca_Uid"] = res.orca_uid
      res = call(req)
      if res.ok? && res.response_number == "00"
        locked_result = nil
        return res
      end
      if !res.ok?
        return res
      end

      req["Request_Number"] = res.response_number
      res = call(req)
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock(locked_result)
    end

    private

    def call(req)
      Result.new(orca_api.call("/api21/medicalmodv35", body: { "medicalv3req5" => req }))
    end

    def unlock(res)
      if res && res["Orca_Uid"]
        req = {
          "Request_Number" => "99",
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_ID" => res.patient_information["Patient_ID"]
        }
        call(req)
      end
    end
  end
end
