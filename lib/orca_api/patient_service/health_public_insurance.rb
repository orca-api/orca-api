# frozen_string_literal: true

module OrcaApi
  class PatientService < Service
    # 患者保険・公費情報を扱うサービス
    #
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
    class HealthPublicInsurance < Service
      # 患者保険・公費情報の取得・更新の結果を表現するクラス
      class Result < ::OrcaApi::Result
        KEYS = Set.new(
          %w(
            Patient_Information
            HealthInsurance_Information
            PublicInsurance_Information
            HealthInsurance_Combination_Information
          )
        )

        def health_public_insurance
          body.select { |k, _|
            KEYS.include?(k)
          } || {}
        end
      end

      # 取得
      #
      # @param id [String] 患者ID
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
      def get(id)
        res = call_01(id)
        if !res.locked?
          unlock(res)
        end
        res
      end

      # 登録・更新・削除
      # > ※３　新規（New）はゼロ、更新（Modify）、削除（Delete）はリクエスト番号＝０１　で返却した保険ＩＤ，公費ＩＤを設定
      # > ※４　新規・更新の時、未設定なら処理日付（基準日の設定があれば基準日＝処理日付）
      # > ※５　保険者番号があれば保険者番号から保険の種類を決定します。保険の種類を変更した時は、ワーニングを返却します。
      # > 　　　保険者番号・保険の種類はどちらかが必須となります。
      # > ※６　未設定の時、保険の種類・開始日から設定します。（オンラインの初期表示と同じ補助区分）
      # > 　　　使用できない補助区分を送信した場合も正しい補助区分に変更し、ワーニングを返却します。
      # > ※７　未設定の時、負担者番号から公費の種類を決定します
      # > ※８ 今回変更なしは空白とします。
      #
      # @param id [String] 患者ID
      # @param params [{"HealthInsurance_Information" => Array, "PublicInsurance_Information" => Array}] 保険公費情報
      # @option params [Array] "HealthInsurance_Information"
      #   保険情報
      #   * "HealthInsurance_Info"
      #     保険情報 (Hash)
      #     * "InsuranceProvider_Mode" ("New", "Modify", "Delete") 処理区分
      #     * "InsuranceProvider_Id" (String) 保険ＩＤ
      #     * "InsuranceProvider_Class" (String) 保険の種類
      #     * "InsuranceProvider_Number" (String) 保険者番号
      #     * "InsuranceProvider_WholeName" (String) 保険の制度名称
      #     * "HealthInsuredPerson_Symbol" (String) 記号/80/全角２０文字
      #     * "HealthInsuredPerson_Number" (String) 番号/80/全角２０文字
      #     * "HealthInsuredPerson_Continuation" (String) 継続区分/1
      #     * "HealthInsuredPerson_Assistance" (String) 補助区分/1/※6
      #     * "RelationToInsuredPerson" (String) 本人家族区分/1/必須
      #     * "HealthInsuredPerson_WholeName" (String) 被保険者名/100/全角２５文字
      #     * "Certificate_StartDate" (String) 適用開始日/10/省略可（処理日付）
      #     * "Certificate_ExpiredDate" (String) 適用終了日/10/省略可（９９９９９９９９）
      #     * "Certificate_GetDate" (String) 資格取得日/10
      #     * "Certificate_CheckDate" (String) 確認日付/10/※４
      #     * "Rate_Class" (String) 高齢者負担区分/1/未使用
      # @option params [Array] "PublicInsurance_Information"
      #   公費情報
      #   * "PublicInsurance_Info"
      #     公費情報 (Hash)
      #     * "PublicInsurance_Mode" ("New", "Modify", "Delete") 処理区分
      #     * "PublicInsurance_Id" (String) 公費ＩＤ/10/※３
      #     * "PublicInsurance_Class" (String) 公費の種類/3/※７
      #     * "PublicInsurance_Name" (String) 公費の制度名称/20
      #     * "PublicInsurer_Number" (String) 負担者番号/8
      #     * "PublicInsuredPerson_Number" (String) 受給者番号/20
      #     * "Certificate_IssuedDate" (String) 適用開始日/10/省略可（処理日付）
      #     * "Certificate_ExpiredDate" (String) 適用終了日/10/省略可（９９９９９９９９）
      #     * "Certificate_CheckDate" (String) 確認日付/10/※４
      #
      # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18351#api2
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032.pdf
      # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v032_err.pdf
      def update(id, params)
        res = call_01(id)
        if !res.locked?
          locked_result = res
        end
        if !res.ok?
          return res
        end
        res = call_02(params, res)
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
          "Orca_Uid" => "",
          "Patient_Information" => {
            "Patient_ID" => id.to_s,
          }
        }
        Result.new(orca_api.call("/orca12/patientmodv32", body: make_body(req)))
      end

      def call_02(params, previous_result)
        res = previous_result
        req = params.merge(
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information
        )
        Result.new(orca_api.call("/orca12/patientmodv32", body: make_body(req)))
      end

      def call_03(previous_result)
        res = previous_result
        req = {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_Information" => res.patient_information,
        }
        if res["HealthInsurance_Information"]
          req["HealthInsurance_Information"] = res["HealthInsurance_Information"]
        end
        if res["PublicInsurance_Information"]
          req["PublicInsurance_Information"] = res["PublicInsurance_Information"]
        end
        Result.new(orca_api.call("/orca12/patientmodv32", body: make_body(req)))
      end

      def unlock(locked_result)
        if locked_result && locked_result.respond_to?(:orca_uid)
          req = {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Orca_Uid" => locked_result.orca_uid,
            "Patient_Information" => locked_result.patient_information,
          }
          orca_api.call("/orca12/patientmodv32", body: make_body(req))
        end
      end

      def make_body(req)
        { "patientmodv3req2" => req }
      end
    end
  end
end
