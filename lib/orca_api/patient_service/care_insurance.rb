module OrcaApi
  class PatientService < Service
    # 介護保険情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036_err.pdf
    class CareInsurance < Service
      # 取得
      def get(id)
        res = call_01(id)
        unlock(res)
        res
      end

      # 更新
      def update(id, args)
        locked_result = res = call_01(id)
        if !res.ok?
          return res
        end
        res = call_02(args, res)
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
        req = args.merge(
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information
        )
        call(req)
      end

      def call(req)
        Result.new(orca_api.call("/orca12/patientmodv36", body: { "patientmodv3req6" => req }))
      end

      def unlock(locked_result)
        if locked_result && locked_result.respond_to?(:orca_uid)
          req = {
            "Request_Number" => "99",
            "Karte_Uid" => locked_result.karte_uid,
            "Orca_Uid" => locked_result.orca_uid,
          }
          call(req)
        end
      end
    end
  end
end
