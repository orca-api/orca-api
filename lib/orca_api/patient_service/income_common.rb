module OrcaApi
  class PatientService < Service
    # 所得者情報・旧姓履歴・特記事項・患者個別情報を扱うサービスの共通処理
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v034.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v034_err.pdf
    class IncomeCommon < Service
      # 取得
      def get(id)
        res = call_01(id)
        if !res.locked?
          unlock(res)
        end
        res
      end

      # 更新・削除
      def update(id, params)
        res = call_01(id)
        if !res.locked?
          locked_result = res
        end
        if !res.ok?
          return res
        end

        res = call_02(params, res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock(locked_result)
      end

      private

      def call_01(id)
        body = {
          "patientmodv3req4" => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => "",
            "Patient_Information" => {
              "Patient_ID" => id.to_s,
            }
          }
        }
        Result.new(orca_api.call("/orca12/patientmodv34", body: body))
      end

      def call_02(params, previous_result)
        res = previous_result
        req = params.merge(
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information
        )
        Result.new(orca_api.call("/orca12/patientmodv34", body: { "patientmodv3req4" => req }))
      end

      def unlock(locked_result)
        if locked_result&.respond_to?(:orca_uid)
          body = {
            "patientmodv3req4" => {
              "Request_Number" => "99",
              "Karte_Uid" => orca_api.karte_uid,
              "Orca_Uid" => locked_result.orca_uid,
              "Patient_Information" => locked_result.patient_information,
            }
          }
          orca_api.call("/orca12/patientmodv34", body: body)
        end
      end
    end
  end
end
