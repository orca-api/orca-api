require_relative "service"

module OrcaApi
  # 帳票印刷を扱うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/20384
  class PrintService < Service
    # 帳票印刷リクエスト
    #
    # @param [String] type
    #   帳票種別。shohosen = 処方箋、okusuri_techo = お薬手帳
    # @param [String] patient_id
    #   患者番号
    # @param [String] invoice_number
    #   伝票番号
    # @param [Boolean] outside_class
    #   院内・院外区分。true = 院外、false = 院内
    # @param [Boolean] push_notification
    #   帳票データ返却と同時にpush通知を行う場合はtrue、そうでない場合はfalseを指定する
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # 処方箋
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/20305
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/push-api/shohosen_req.pdf
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/push-api/shohosen.pdf
    #
    # お薬手帳
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/20306
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/push-api/okusuri_techo_req.pdf
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/push-api/okusuri_techo.pdf
    def create(type, patient_id, invoice_number, outside_class, push_notification = false)
      case type.to_s
      when "shohosen"
        path = "/api01rv2/prescriptionv2"
        request_name = "prescriptionv2req"
      when "okusuri_techo"
        path = "/api01rv2/medicinenotebookv2"
        request_name = "medicine_notebookv2req"
      else
        raise ArgumentError, "対応していない帳票種別です: #{type}"
      end

      req = {
        "Request_Number" => push_notification ? "01" : "02",
        "Patient_ID" => patient_id.to_s,
        "Invoice_Number" => invoice_number.to_s,
        "Outside_Class" => outside_class ? "True" : "False",
      }

      FormResult.new(orca_api.call(path, body: { request_name => req }))
    end
  end
end
