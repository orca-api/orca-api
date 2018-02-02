module OrcaApi
  class PatientService < Service
    # 患者保険・公費情報を扱うサービスの共通処理
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class HealthPublicInsuranceCommon < Service
      # 患者保険・公費情報を取得する
      #
      # @param [String] id
      #   患者ID
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
      def get(id)
        res = call_01(id)
        unlock(res)
        res
      end

      # 患者保険・公費情報を更新する
      #
      # @param [String] id
      #   患者ID
      # @param [Hash] args
      #   保険情報
      #   * WIP
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
      def update(id, args)
        locked_result = res = call_01(id)
        if !res.ok?
          return res
        end
        res = call_02(args, res)
        if !res.ok?
          return res
        end
        res = call_03(res)
        if res.ok?
          locked_result = nil
        end
        res
      ensure
        unlock(locked_result)
      end

      private

      def call_01(id)
        req = {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_Information" => {
            "Patient_ID" => id.to_s,
          }
        }
        call(req)
      end

      def call_02(args, res)
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          insurance_information_name => args,
        }
        call(req)
      end

      def call_03(res)
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
          insurance_information_name => res[insurance_information_name],
        }
        call(req)
      end

      def unlock(locked_result)
        if locked_result && locked_result.respond_to?(:orca_uid)
          req = {
            "Request_Number" => "99",
            "Karte_Uid" => locked_result.karte_uid,
            "Orca_Uid" => locked_result.orca_uid,
            "Patient_Information" => locked_result.patient_information,
          }
          call(req)
        end
      end

      def call(req)
        Result.new(orca_api.call("/orca12/patientmodv32", body: { "patientmodv3req2" => req }))
      end
    end
  end
end
