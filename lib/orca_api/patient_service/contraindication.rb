# frozen_string_literal: true

module OrcaApi
  class PatientService < Service
    # 患者禁忌薬剤情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api7
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v037.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v037_err.pdf
    class Contraindication < Service
      # 患者の禁忌薬剤情報を取得する
      #
      # @param [String] patient_id
      #   患者番号
      def get(patient_id)
        first_result = call_01 patient_id
      ensure
        unlock first_result
      end

      # 患者の禁忌薬剤情報を更新、または削除する
      #
      # @param [String] patient_id
      #   患者番号
      # @param [Hash{String => String, Hash}] params
      #   禁忌薬剤情報
      # @option params [String] "Contra_Mode" "Modify"か"Delete"を指定する
      def update(patient_id, params)
        first_result = call_01 patient_id
        return first_result unless first_result.ok?

        call_02(params, first_result).tap do |result|
          # 処理成功したらロックの解除は不要なため
          first_result = nil if result.ok?
        end
      ensure
        unlock first_result
      end

      private

      def call_01(patient_id)
        body = wrap({
                      "Request_Number" => "01",
                      "Karte_Uid" => orca_api.karte_uid,
                      "Orca_Uid" => "",
                      "Patient_Information" => {
                        "Patient_ID" => patient_id.to_s,
                      }
                    })
        Result.new(orca_api.call("/orca12/patientmodv37", body: body))
      end

      def call_02(params, previous_result)
        body = wrap({
                      "Request_Number" => previous_result.response_number,
                      "Karte_Uid" => orca_api.karte_uid,
                      "Orca_Uid" => previous_result.orca_uid,
                      "Patient_Information" => previous_result.patient_information,
                      "Patient_Contra_Information" => extract_contra_information(params),
                    })
        Result.new(orca_api.call("/orca12/patientmodv37", body: body))
      end

      def call_99(result)
        body = wrap({
                      "Request_Number" => "99",
                      "Karte_Uid" => orca_api.karte_uid,
                      "Orca_Uid" => result.orca_uid,
                      "Patient_Information" => {
                        "Patient_ID" => result.patient_information["Patient_ID"]
                      },
                    })
        orca_api.call("/orca12/patientmodv37", body: body)
      end

      def unlock(result)
        return unless result
        return if result.locked?
        return unless result.respond_to?(:orca_uid)

        call_99(result)
      end

      def extract_contra_information(params)
        if params["Contra_Mode"] == "Modify"
          {
            "Contra_Mode" => "Modify",
            "Patient_Contra_Info" => params["Patient_Contra_Info"],
          }
        else
          {
            "Contra_Mode" => "Delete",
          }
        end
      end

      def wrap(hash)
        { "patientmodv3req7" => hash }
      end
    end
  end
end
