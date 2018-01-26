module OrcaApi
  class PatientService < Service
    # 介護保険情報・介護認定情報を扱うサービスの共通処理
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api6
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036_err.pdf
    class CareCommon < Service
      # 介護保険情報、または介護認定情報を取得する
      #
      # @param [String] id
      #   患者ID
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036_err.pdf
      def get(id)
        res = call_01(id)
        unlock(res)
        res
      end

      # 介護保険情報、または介護認定情報を更新する
      #
      # @param [String] id
      #   患者ID
      # @param [Hash] args
      #   * "Care_Insurance_Information" (Hash)
      #     介護保険情報
      #     * "Insurance_Mode" (String)
      #       処理区分。
      #       介護保険情報・介護認定情報毎に、更新（Modify）、削除（Delete）の指定を行います。
      #       今回変更なしは空白とします。
      #       更新（Modify）は処理単位毎に一括削除・一括登録を行います。１レコード毎の更新はできません。
      #       削除（Delete）は処理単位毎に一括削除します。
      #     * "Care_Insurance_Info" (Array<Hash>)
      #       介護保険情報
      #       * "InsuranceProvider_Number" (String)
      #         保険者番号
      #       * "HealthInsuredPerson_Number" (String)
      #         被保険者番号
      #       * "Certificate_StartDate" (String)
      #         有効開始日。必須。YYYY-mm-dd形式。
      #       * "Certificate_ExpiredDate" (String)
      #         有効終了日。YYYY-mm-dd形式。
      #   * "Care_Certification_Information" (Hash)
      #     介護認定情報
      #     * "Certification_Mode" (String)
      #       処理区分。
      #       介護保険情報・介護認定情報毎に、更新（Modify）、削除（Delete）の指定を行います。
      #       今回変更なしは空白とします。
      #       更新（Modify）は処理単位毎に一括削除・一括登録を行います。１レコード毎の更新はできません。
      #       削除（Delete）は処理単位毎に一括削除します。
      #     * Certification_Info (Array<Hash>)
      #       介護認定情報
      #       * "Need_Care_State_Code" (String)
      #         要介護状態。必須
      #       * "Certification_Date" (String)
      #         認定日。YYYY-mm-dd形式
      #       * "Certificate_StartDate" (String)
      #         有効開始日。必須
      #       * "Certificate_ExpiredDate" (String)
      #         有効終了日
      # @return [OrcaApi::Result]
      #   日レセからのレスポンス
      #
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v036_err.pdf
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
