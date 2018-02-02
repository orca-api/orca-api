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
      #   * "HealthInsurance_Info" (Array[Hash])
      #     患者保険情報
      #     * "InsuranceProvider_Mode" (String)
      #       処理区分。
      #       New：新規、Modify：更新、Delete：削除。
      #       今回変更なしは空白とします。
      #     * "InsuranceProvider_Id" (String)
      #       保険ＩＤ。
      #       新規（New）はゼロ、更新（Modify）、削除（Delete）は保険IDを指定すること
      #     * "InsuranceProvider_Class" (String)
      #       保険の種類。
      #       保険者番号があれば保険者番号から保険の種類を決定します。保険の種類を変更した時は、ワーニングを返却します。
      #       保険者番号・保険の種類はどちらかが必須となります。
      #     * "InsuranceProvider_Number" (String)
      #       保険者番号
      #       保険者番号があれば保険者番号から保険の種類を決定します。保険の種類を変更した時は、ワーニングを返却します。
      #       保険者番号・保険の種類はどちらかが必須となります。
      #     * "InsuranceProvider_WholeName" (String)
      #       保険の制度名称
      #     * "HealthInsuredPerson_Symbol" (String)
      #       記号。全角２０文字。
      #     * "HealthInsuredPerson_Number" (String)
      #       番号。全角２０文字。
      #     * "HealthInsuredPerson_Continuation" (String)
      #       継続区分
      #     * "HealthInsuredPerson_Assistance" (String)
      #       補助区分。
      #       未設定の時、保険の種類・開始日から設定します（オンラインの初期表示と同じ補助区分）。
      #       使用できない補助区分を送信した場合も正しい補助区分に変更し、ワーニングを返却します。
      #     * "RelationToInsuredPerson" (String)
      #       本人家族区分。必須。
      #     * "HealthInsuredPerson_WholeName" (String)
      #       被保険者名。全角２５文字。
      #     * "Certificate_StartDate" (String)
      #       適用開始日。省略可（処理日付）
      #     * "Certificate_ExpiredDate" (String)
      #       適用終了日。省略可（９９９９９９９９）
      #     * "Certificate_GetDate" (String)
      #       資格取得日
      #     * "Certificate_CheckDate" (String)
      #       確認日付。
      #       新規・更新の時、未設定なら処理日付（基準日の設定があれば基準日＝処理日付）。
      #     * "Rate_Class" (String)
      #       高齢者負担区分。未使用
      #   * "PublicInsurance_Info" (Array[Hash])
      #     患者公費情報
      #     * "PublicInsurance_Mode" (String)
      #       処理区分。
      #       New：新規、Modify：更新、Delete：削除。
      #       今回変更なしは空白とします。
      #     * "PublicInsurance_Id" (String)
      #       公費ＩＤ。
      #       新規（New）はゼロ、更新（Modify）、削除（Delete）は公費ＩＤを指定すること
      #     * "PublicInsurance_Class" (String)
      #       公費の種類。
      #       未設定の時、負担者番号から公費の種類を決定します
      #     * "PublicInsurance_Name" (String)
      #       公費の制度名称
      #     * "PublicInsurer_Number" (String)
      #       負担者番号
      #     * "PublicInsuredPerson_Number" (String)
      #       受給者番号
      #     * "Certificate_IssuedDate" (String)
      #       適用開始日。
      #       省略可（処理日付）。
      #     * "Certificate_ExpiredDate" (String)
      #       適用終了日。
      #       省略可（９９９９９９９９）
      #     * "Certificate_CheckDate" (String)
      #       確認日付。
      #       新規・更新の時、未設定なら処理日付（基準日の設定があれば基準日＝処理日付）
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
