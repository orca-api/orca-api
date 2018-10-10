require_relative "service"

module OrcaApi
  # 診療行為を扱うサービスを表現したクラス
  # 診療行為の登録の流れを以下に示す。
  #
  #  * (1) 患者の保険情報と診察料のデフォルト値の返却: get_default
  #    * 取得したデフォルト値を元に、次のメソッドの引数を組み立てる。
  #    * 詳しくは `example/medical_practice_service/get_default.rb` を参照。
  #  * (2) 診察料情報の取得: get_examination_fee
  #    * 取得した診察料情報を元に、次のメソッドの引数を組み立てる。
  #    * 詳しくは `example/medical_practice_service/get_examination_fee.rb` を参照。
  #  * (3) 診療情報及び請求情報の取得: calc_medical_practice_fee
  #    * 取得した診療情報及び請求情報を元に、次のメソッドの引数を組み立てる。
  #    * 詳しくは `example/medical_practice_service/cal_medical_practice_fee.rb` を参照。
  #  * (4) 診療行為の登録: create
  #    * 詳しくは `example/medical_practice_service/crud.rb` を参照。
  #
  # @example 診療行為の訂正
  #   # 対象の受診履歴を指定すること以外は、診療情報及び請求情報の取得と診療行為の登録と同じ流れ
  #   medical_information = result.medical_information
  #   #> ここで診療行為登録内容を訂正する
  #   #> 時間外区分も設定する
  #   medical_information["OffTime"] = "0" # 時間外区分/1/外来時間外区分（０から８）とする（環境設定の外来時間外区分）
  #   params = {
  #     #> ハッシュの値は、受信履歴を取得するためにInvoice_Numberを指定すること以外は
  #     #> 診察料情報の取得、診療情報及び請求情報の取得と同じ
  #     "Invoice_Number" => result.invoice_number, # 伝票番号/7/訂正時必須
  #
  #     "Patient_ID" => patient_id.to_s, # 患者番号/20/必須
  #     "Perform_Date" => result.perform_date, # 診療日付/10/未設定はシステム日付
  #     "Perform_Time" => "10:30:00", # 診療時間/8/未使用
  #     "Diagnosis_Information" => { # 送信内容
  #       "Department_Code" => result.department_code, # 診療科/2/必須
  #       "Physician_Code" => result.physician_code, # ドクターコード/5
  #       "Outside_Class" => result.body["Outside_Class"], # 院内・院外区分/5/院内＝False、院外＝True ※2
  #       "HealthInsurance_Information" => result.health_insurance_information, # 保険情報
  #       "Medical_Information" => medical_information, # 診療送信内容
  #     },
  #   }
  #   #> ※２　投薬の院内・院外が診療種別から判断できない場合に、剤点数≠ゼロを院内、剤点数＝ZEROかつ薬剤がある場合を院外とする。
  #   result = medical_practice_service.calc_medical_practice_fee(params)
  #   if !result.ok?
  #     # エラー
  #   end
  #   result.medical_information #=> 診療情報
  #   result.cd_information #=> 請求情報
  #
  #   params["Base_Date"] = "" # 基準日/10/収納発行日を診療日付以外とする時に設定
  #   params["Ic_Code"] = result.cd_information["Ic_Code"] # 入金方法/2/未設定は、システム管理・患者登録設定内容
  #   params["Ic_Request_Code"] = result.cd_information["Ic_Request_Code"] # 入金取り扱い区分/1/※５
  #   params["Ic_All_Code"] = "" # 一括入返金区分/1/※６
  #   params["Cd_Information"] = { # 収納情報
  #     "Ad_Money1" => "0", # 調整金１/10/※2 マイナス可　　※3
  #     "Ad_Money2" => "0", # 調整金２/10/※2 マイナス可　　※3
  #     "Ic_Money" => result.cd_information["Cd_Information2"]["Ic_Money"], # 入金額/10/今回合計請求額以下であること　マイナス不可
  #     "Re_Money" => "", # 返金額/10/※７　マイナス不可
  #   }
  #   params["Print_Information"] = { # 印刷区分 ※８
  #     "Print_Prescription_Class" => "0", # 処方せん印刷区分/1/０：発行なし、１：発行あり、２：院内処方発行
  #     "Print_Invoice_Receipt_Class" => "0", # 請求書兼領収書印刷区分/1/※９
  #     "Print_Statement_Class" => "0", # 診療費明細書印刷区分/1/０：発行なし、１：発行あり
  #     "Print_Medicine_Information_Class" => "0", # 薬剤情報印刷区分/1/０：発行なし、１：発行あり、２：院外分発行
  #     "Print_Medication_Note_Class" => "0", # 薬手帳印刷区分/1/０：発行なし、１：発行あり、２：院外分発行
  #     "Print_Appointment_Form_Class" => "0", # 予約票印刷区分/1/０：発行なし、１：発行あり
  #   }
  #   result = medical_practice_service.create(params)
  #   if !result.ok?
  #     # エラー
  #   end
  #   result.medical_information #=> 診療情報
  #   result.cd_information #=> 請求情報
  #
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf
  class MedicalPracticeService < Service
    # 診療行為APIのレスポンスクラスの基底クラス
    class ResponseResult < ::OrcaApi::Result
      def_info :medical_warnings, "Medical_Message_Information", "Medical_Warning_Info"

      # @param [String] raw
      #   JSON文字列
      # @param [Array<String>, nil] ignore_medical_warnings
      #   無視する警告コード
      def initialize(raw, ignore_medical_warnings = nil)
        super(raw)
        @ignore_medical_warnings = Array[ignore_medical_warnings].flatten.compact
      end

      # APIレスポンスに警告コードが含まれていればfalseを返す。それ以外の場合は、 OrcaApi::Result#ok? を呼び出す
      # @see OrcaApi::Result#ok?
      def ok?
        warning_codes.empty? ? super : false
      end

      private

      def warning_codes
        warning_codes = medical_warnings.map { |i| i["Medical_Warning"] }
        (warning_codes - @ignore_medical_warnings)
      end
    end

    # 診療処理開始または、デフォルト保険組合せ取得のレスポンスを表現したクラス
    class Response1Result < ResponseResult
      # @example
      #   res = Response1Result.new({
      #                               "response" => {
      #                                 "Medical_Information" => [
      #                                   { "Medical_Info" => [1] },
      #                                   # :
      #                                   { "Medical_Info" => [2] },
      #                                 ]
      #                               }
      #                             }.to_json)
      #   res.medical_information
      #   # => [ { "Medical_Info" => [1] }, { "Medical_Info" => [2] } ]
      #
      # @return [Array<Hash>]
      def medical_information
        Array(body["Medical_Information"])
      end

      # @example
      #   res = Response1Result.new({
      #                               "response" => {
      #                                 "Medical_Information" => [
      #                                   { "Medical_Info" => [1] },
      #                                   # :
      #                                   { "Medical_Info" => [2] },
      #                                 ]
      #                               }
      #                             }.to_json)
      #   res.medical_info
      #   # => [1, 2]
      #
      # @return [Array<Hash>]
      def medical_info
        medical_information.flat_map do |mi|
          Array(mi["Medical_Info"])
        end
      end
    end

    # 診療内容チェックのレスポンスを表現したクラス
    class Response2Result < ResponseResult
      def_info :medical_info, "Medical_Information", "Medical_Info"

      # @return [Hash]
      def medical_information
        Hash(body["Medical_Information"])
      end
    end

    # 診療行為確認・登録のレスポンスを表現したクラス
    class Response3Result < ResponseResult
      def_info :medical_info, "Medical_Information", "Medical_Info"

      # @return [Hash]
      def medical_information
        Hash(body["Medical_Information"])
      end

      # @return [Hash]
      def cd_information
        Hash(body["Cd_Information"])
      end

      # @return [Hash]
      def print_information
        Hash(body["Print_Information"])
      end
    end

    # 選択項目が未指定であることを表現するクラス
    class UnselectedError < ::OrcaApi::Result
      def ok?
        false
      end

      def message
        '選択項目が未指定です。'
      end
    end

    # 削除可能な剤の削除指示が未指定であることを表現するクラス
    class EmptyDeleteNumberInfoError < ::OrcaApi::Result
      def ok?
        false
      end

      def message
        '削除可能な剤の削除指示が未指定です。'
      end
    end

    # デフォルト値の返却
    #
    # @param [Hash] params
    #   * "Patient_ID" (String)
    #     患者番号。必須。
    #   * "Perform_Date" (String)
    #     診療日付。YYYY-mm-dd形式。未設定はシステム日付。
    #   * "Diagnosis_Information" (Hash)
    #     * "Department_Code" (String)
    #       診療科。必須。
    #     * "Medical_Information" (Hash)
    #       * "Doctors_Fee" (String)
    #         診察料区分。
    #         01: 初診、02:再診、03:電話再診、09:診察料なし。
    #         設定がなければ、病名などから診察料を返却する。
    # @return [Response1Result]
    #   日レセからのレスポンス
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api10
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api021s1v3.pdf
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api021s1v3_err.pdf
    def get_default(params)
      body = {
        "medicalv3req1" => params.merge(
          "Request_Number" => "00",
          "Karte_Uid" => orca_api.karte_uid
        )
      }
      Response1Result.new(
        orca_api.call("/api21/medicalmodv31", body: body), ignore_medical_warnings(params)
      )
    end

    # 診察料情報の取得
    #
    # @param params [Hash]
    #   * "Patient_ID" (String)
    #     患者番号/20/必須
    #   * "Perform_Date" (String)
    #     診療日付/10/未設定はシステム日付
    #   * "Perform_Time" (String)
    #     診療時間/8/未使用
    #   * "Diagnosis_Information" (Hash)
    #     * "Department_Code" (String)
    #       診療科/2/必須
    #     * "Physician_Code" (String)
    #       ドクターコード/5
    #     * "HealthInsurance_Information" (Hash)
    #       保険情報。
    #       保険組合せ又は保険・公費から保険組合せを決定。
    #       包括分入力（保険組合せ＝９９９９、保険の種類＝９９）。
    #       診察料区分（Doctors_Fee）＝０９　は省略可。
    #       * "Insurance_Combination_Number" (String)
    #         保険組合せ番号/4/指定があれば優先
    #       * "InsuranceProvider_Class" (String)
    #         保険の種類/3
    #       * "InsuranceProvider_Number" (String)
    #         保険者番号/8
    #       * "InsuranceProvider_WholeName" (String)
    #         保険の制度名称/20
    #       * "HealthInsuredPerson_Symbol" (String)
    #         記号/80
    #       * "HealthInsuredPerson_Number" (String)
    #         番号/80
    #       * "HealthInsuredPerson_Continuation" (String)
    #         継続区分/1
    #       * "HealthInsuredPerson_Assistance" (String)
    #         補助区分/1
    #       * "RelationToInsuredPerson" (String)
    #         本人家族区分/1
    #       * "HealthInsuredPerson_WholeName" (String)
    #         被保険者名/100
    #       * "Certificate_StartDate" (String)
    #         適用開始日/10
    #       * "Certificate_ExpiredDate" (String)
    #         適用終了日/10
    #       * "PublicInsurance_Information" (Hash)
    #         公費情報　（４）/4
    #         * "PublicInsurance_Class" (String)
    #           公費の種類/3
    #         * "PublicInsurance_Name" (String)
    #           公費の制度名称/20
    #         * "PublicInsurer_Number" (String)
    #           負担者番号/8
    #         * "PublicInsuredPerson_Number" (String)
    #           受給者番号/20
    #         * "Certificate_IssuedDate" (String)
    #           適用開始日/10
    #         * "Certificate_ExpiredDate" (String)
    #           適用終了日/10
    #     * "Medical_Information" (Hash)
    #       診療送信内容
    #       * "OffTime" (String)
    #         時間外区分/1/外来時間外区分（０から８）とする（環境設定の外来時間外区分）
    #       * "Doctors_Fee" (String)
    #         診察料区分/2。
    #         ０１＝初診、０２＝再診、０３＝電話再診、０９＝診察料なし。
    #       * "Medical_Class" (String)
    #         診療種別区分/3/診察料コードの診療区分
    #       * "Medical_Class_Name" (String)
    #         診療種別区分名称/40
    #       * "Medication_Info" (Hash)
    #         診療行為
    #         * "Medication_Code" (String)
    #           診療コード/9/診察料コード。
    #           コードが使用できるかのチェックを行う。
    #           診察料区分の設定がない時のみチェックを行う。
    #         * "Medication_Name" (String)
    #           名称/80
    # @return [Response1Result]
    #   日レセからのレスポンス
    #
    # @example
    #   params = {
    #     "Patient_ID" => patient_id,
    #     "Perform_Date" => "",
    #     "Perform_Time" => "",
    #     "Diagnosis_Information" => {
    #       "Department_Code" => "01",
    #       "Physician_Code" => "10001",
    #       "HealthInsurance_Information" => {
    #         "Insurance_Combination_Number" => insurance_combination_number,
    #       },
    #       "Medical_Information" => {
    #         "OffTime" => "0",
    #         "Doctors_Fee" => doctors_fee,
    #         "Medical_Class" => "",
    #         "Medical_Class_Name" => "",
    #         "Medication_Info" => {
    #           "Medication_Code" => "",
    #         }
    #       },
    #     },
    #   }
    #   result = medical_practice_service.get_examination_fee(params)
    #   if !result.ok?
    #     # エラー処理
    #   end
    #   medical_info = result.medical_information[0]["Medical_Info"] #=> 診察料情報
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api1
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf （診療処理開始）
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api_err.pdf
    def get_examination_fee(params)
      res = call_01_for_create(params)
      if !res.locked?
        unlock_for_create(res)
      end
      res
    end

    # 診療情報及び請求情報の取得
    #
    # @param params [Hash]
    #   * "Patient_ID" (String)
    #     患者番号/20/必須
    #   * "Perform_Date" (String)
    #     診療日付/10/未設定はシステム日付
    #   * "Perform_Time" (String)
    #     診療時間/8/未使用
    #   * "Diagnosis_Information" (Hash)
    #     MedicalPracticeService#get_examination_fee の "Diagnosis_Information" と同じデータを渡す。
    #     以下は追加パラメータ
    #     * "Outside_Class" ("False", "True")
    #       院内・院外区分/5/院内＝False、院外＝True（未設定はシステム管理）
    #     * "Medical_Information" ({ "Medical_Info" => Array<Hash> })
    #       診療行為情報
    #       * "Medical_Class" (String)
    #         診療種別区分/3/必須
    #       * "Medical_Class_Name" (String)
    #         診療種別区分名称/40
    #       * "Medical_Class_Number" (String)
    #         回数/3/未設定は１、０はエラー
    #       * "Medication_Info" (Array<Hash>)
    #         診療剤明細（５０）/50
    #         * "Medication_Code" (String)
    #           診療コード/9
    #         * "Medication_Name" (String)
    #           名称/80。
    #           名称を入力するコメントコード（81XXXXXXX,83XXXXXXXX,0083XXXXX、0085～）は全内容（点数マスタの名称＋入力内容）。
    #         * "Medication_Number" (String)
    #           数量/11/未設定は１、０はエラー
    #         * "Medication_Moeny" (String)
    #           自費金額/7/金額ゼロで登録してある自費コードの金額（消費税込）
    #         * "Medication_Input_Info" (<{ "Medication_Input_Code" => String }>)
    #           コメント埋め込み数値（５）/5
    #           * "Medication_Input_Code" (String)
    #             コメント埋め込み数値/8/（１）から順に数値を編集
    #         * "Medication_Film_Comp_Number" (String)
    #           フィルム分画数/3
    #         * "Medication_Continue" (String)
    #           継続コメント指示区分/1
    #         * "Medication_Internal_Kinds" (String)
    #           内服種類数指示区分/1/１：内服種類数を１とする
    #         * "Medication_No_Addition_Class" (String)
    #           加算自動算定なし/3。
    #           在医総管・施医総菅（C002）の在宅療養実績加算、精神通院（I002）の２０未満の加算を自動算定しない場合に「Yes」を設定します。
    #         * "Medication_Auto_Addition" (String)
    #           自動区分/1。
    #           レスポンス内容をリクエスト内容として返却する時そのまま返却すること。変更した場合の不具合は保障できない。
    #   * "Medical_Select_Information" (Array<Hash>)
    #     確認領域
    #     * "Medical_Select" (String)
    #       確認メッセージコード
    #     * "Select_Answer" ("Ok", "No")
    #       確認メッセージ返答
    #   * "Delete_Number_Info" (Array<Hash>)
    #     在削除連番
    #     * "Delete_Number" (String)
    #       在削除連番
    # @return [OrcaApi::MedicalPracticeService::Response3Result]
    #   日レセからのレスポンス
    # @return [OrcaApi::MedicalPracticeService::UnselectedError]
    #   選択項目がある場合の日レセからのレスポンス
    # @return [OrcaApi::MedicalPracticeService::EmptyDeleteNumberInfoError]
    #   削除可能な剤がある場合の日レセからのレスポンス
    #
    # @example
    #   # 診療種別区分を指定せずに薬剤を追加する。
    #   medical_info.last["Medication_Info"] << {
    #     "Medication_Code" => "620002477", # 薬剤コード/9
    #     "Medication_Name" => "ベザレックスＳＲ錠１００　１００ｍｇ", # 省略可能
    #     "Medication_Number" => "1",
    #   }
    #   # 診療種別区分として手術を指定して薬剤を追加する。
    #   medical_info << {
    #     "Medical_Class" => "500",
    #     "Medication_Info" => [
    #       {
    #         "Medication_Code" => "620002477", # 薬剤コード/9
    #         "Medication_Name" => "ベザレックスＳＲ錠１００　１００ｍｇ", # 省略可能
    #         "Medication_Number" => "1",
    #       },
    #     ],
    #   }
    #   params["Diagnosis_Information"]["Medical_Information"]["Medical_Info"] = medical_info
    #   params["Diagnosis_Information"]["Outside_Class"] = "True" # 院内・院外区分/5/院内＝False、院外＝True（未設定はシステム管理）
    #   result = medical_practice_service.calc_medical_practice_fee(params)
    #   while !result.ok?
    #     case result
    #     when OrcaApi::MedicalPracticeService::UnselectedError
    #       result.medical_select_information #=> 選択項目
    #
    #       # 選択項目が存在するため、paramsに選択項目への回答を追加する。
    #       # 複数の選択項目がある場合は、都度このエラーが発生するため、すべての回答を追加すること。
    #       params["Medical_Select_Information"] = [
    #         {
    #           "Medical_Select" => "0113", # 確認メッセージコード/4
    #           "Medical_Select_Message" => "特定疾患処方管理加算が算定できます。ＯＫで自動算定します。", # 確認メッセージ/100/省略可能
    #           "Select_Answer" => "No", # 確認メッセージ返答/3/Ok 、No (OK,NO)
    #         },
    #         {
    #           "Medical_Select": "2003",
    #           "Medical_Select_Message": "手帳記載加算（薬剤情報提供料）を算定します。よろしいですか？",
    #           "Select_Answer" => "Yes",
    #         },
    #       ]
    #     when OrcaApi::MedicalPracticeService::EmptyDeleteNumberInfoError
    #       result.medical_information #=> 診療情報情報。削除可能な剤には"Medical_Delete_Number"が存在する。
    #       # "Medical_Delete_Number"が存在する場合のHashの例: spec/fixtures/orca_api_responses/api21_medicalmodv32_03_delete.json
    #
    #       # 削除可能な剤が存在するため、paramsに削除するかどうかを追加する。
    #       params["Delete_Number_Info"] = [
    #         { "Delete_Number" => "01" },
    #       ]
    #     else
    #       # その他のエラー
    #       break
    #     end
    #     result = medical_practice_service.calc_medical_practice_fee(params)
    #   end
    #   if !result.ok?
    #     # エラー
    #   end
    #   result.medical_information #=> 診療情報
    #   result.cd_information #=> 請求情報
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api2
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api3
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api4
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf （診療内容チェック）（診療行為確認・登録）
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api_err.pdf
    def calc_medical_practice_fee(params)
      res = if params["Invoice_Number"]
              call_01_for_update(params, "Modify")
            else
              call_01_for_create(params)
            end
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end

      calc_medical_practice_fee_without_unlock(params, res)
    ensure
      unlock_for_create(locked_result)
    end

    # 診療行為の登録
    #
    # @param params [Hash]
    #   * "Base_Date" (String)
    #     基準日/10/収納発行日を診療日付以外とする時に設定
    #   * "Ic_Code" (String)
    #     入金方法/2/未設定は、システム管理・患者登録設定内容
    #   * "Ic_Request_Code" (String)
    #     入金取り扱い区分/1。
    #     訂正時は１のみとする。初期設定はシステム管理による。
    #     * 1: 今回請求分のみ入力
    #     * 2: 今回分・伝票の古い未収順に入金
    #     * 3: 今回分・伝票の新しい未収順に入金
    #     * 4: 伝票の古い未収順に入金
    #     * 5: 伝票の新しい未収順に入金
    #   * "Ic_All_Code" (String)
    #     一括入返金区分/1。
    #     入金取り扱い区分が２から５で、前回までの未収額・前回までの過入金がある時のみ「１」で一括入返金処理を行う。
    #   * "Cd_Information" (Hash)
    #     収納情報
    #     * "Ad_Money1" (String)
    #       調整金１/10/マイナス可。
    #       請求額＋(調整金１＋調整金２）がマイナスはエラー。
    #     * "Ad_Money2" (String)
    #       調整金２/10/マイナス可。
    #       請求額＋(調整金１＋調整金２）がマイナスはエラー。
    #     * "Ic_Money" (String)
    #       入金額/10/今回合計請求額以下であること。マイナス不可
    #     * "Re_Money" (String)
    #       返金額/10/マイナス不可。
    #       新規は前回過入金がある時に全額設定、訂正時（前回請求額－今回請求額）がマイナスの時のみ全額設定（返金するときのみ）。
    #   * "Print_Information" (Hash)
    #     印刷区分
    #     * "Print_Prescription_Class" (String)
    #       処方せん印刷区分/1/０：発行なし、１：発行あり、２：院内処方発行
    #     * "Print_Invoice_Receipt_Class" (String)
    #       請求書兼領収書印刷区分/1。
    #       * 新規
    #         * 0：発行なし
    #         * 1：発行あり
    #         * 2：発行あり（1：と違いはない）
    #       * 訂正
    #         * 0：発行なし
    #         * 1：発行あり（訂正分）
    #         * 2：発行あり（合計）
    #     * "Print_Statement_Class" (String)
    #       診療費明細書印刷区分/1/０：発行なし、１：発行あり
    #     * "Print_Medicine_Information_Class" (String)
    #       薬剤情報印刷区分/1/０：発行なし、１：発行あり、２：院外分発行
    #     * "Print_Medication_Note_Class" (String)
    #       薬手帳印刷区分/1/０：発行なし、１：発行あり、２：院外分発行
    #     * "Print_Appointment_Form_Class" (String)
    #       予約票印刷区分/1/０：発行なし、１：発行あり
    # @return [Response3Result]
    #   日レセからのレスポンス
    #
    # @example
    #   result = medical_practice_service.create(params)
    #   if !result.ok?
    #     # エラー処理
    #   end
    #   result.invoice_number #=> 伝票番号
    #   result.medical_information #=> 診療行為情報
    #   result.cd_information #=> 請求情報
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api5
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf （診療行為確認・登録）
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api_err.pdf
    def create(params)
      res = if params["Invoice_Number"]
              call_01_for_update(params, "Modify")
            else
              call_01_for_create(params)
            end
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end

      res = calc_medical_practice_fee_without_unlock(params, res)
      if !res.ok?
        return res
      end

      res = call_05(params, res)
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock_for_create(locked_result)
    end

    # 診療行為の取得
    #
    # @param params
    #   * "Patient_ID" (String)
    #     患者番号/20/必須
    #   * "Perform_Date" (String)
    #     診療日付/10/未設定はシステム日付
    #   * "Invoice_Number" (String)
    #     伝票番号/7。
    #     伝票番号がない時のみ、診療科・保険組合せ・連番から受診履歴を決定する。
    #   * "Department_Code" (String)
    #     診療科/1。
    #     伝票番号を優先とする。
    #   * "Insurance_Combination_Number" (String)
    #     保険組合せ番号/4。
    #     伝票番号を優先とする。
    #   * "Sequential_Number" (String)
    #     連番/1。
    #     伝票番号を優先とする。
    #     連番の未設定は１とする。
    # @return [OrcaApi::Result]
    #   日レセからのレスポンス
    #
    # @example
    #   result = medical_practice_service.get(params)
    #   if !result.ok?
    #     # エラー処理
    #   end
    #   result.medical_information #=> 診療行為登録内容
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api7
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf 一体化API診療行為削除
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api_err.pdf
    def get(params)
      res = call_01_for_update(params, "Modify")
      if !res.locked?
        locked_result = res
      end
      res
    ensure
      unlock_for_update(locked_result)
    end

    # 診療行為の削除
    #
    # @param (see #get)
    # @return (see #get)
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api6
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf 一体化API診療行為削除
    # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/api/haori/HAORI_Layout/api_err.pdf
    def destroy(params)
      res = call_01_for_update(params, "Delete")
      if !res.locked?
        locked_result = res
      end
      if res.api_result != "S30"
        return res
      end

      res = call_02_for_delete(res)
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock_for_update(locked_result)
    end

    alias update create

    # 薬剤併用禁忌チェック
    #
    # @param params [Hash]
    #   薬剤併用禁忌情報
    #   * "Patient_ID" (String)
    #     患者ID
    #   * "Perform_Month" (String)
    #     診療年月/7/未設定はシステム日付
    #   * "Check_Term" (String)
    #     チェック期間/2/未設定はシステム管理の相互作用チェック期間
    #   * "Medical_Information" (Array<Hash>)
    #     チェック薬剤情報
    #     * "Medication_Code" (String)
    #       薬剤コード/9
    #     * "Medication_Name" (String)
    #       薬剤名称
    #
    # @example
    #   params = {
    #     "Patient_ID" => patient_id,
    #     "Perform_Month" => "",
    #     "Check_Term" => "",
    #     "Medical_Information" => [
    #       {
    #         "Medication_Code" => "620002477"
    #       },
    #       {
    #         "Medication_Code" => "610422262"
    #       },
    #     ],
    #   }
    #   result = medical_practice_service.check_contraindication(params)
    #   if !result.ok?
    #     # エラー処理
    #   end
    #   result.perform_month #=> 診療年月
    #   result.patient_information #=> 患者情報
    #   result.medical_information #=> チェック薬剤情報
    #   result.symptom_information #=> 症状詳記内容
    #
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api8
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api0214.pdf
    def check_contraindication(params)
      body = {
        "contraindication_checkreq" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
        }.merge(params),
      }
      Result.new(orca_api.call("/api01rv2/contraindicationcheckv2", body: body))
    end

    private

    def ignore_medical_warnings(params)
      (params["Ignore_Medical_Warnings"] || []).map { |i| i["Medical_Warning"] }
    end

    def calc_medical_practice_fee_without_unlock(params, get_examination_fee_result)
      res = call_02(params, get_examination_fee_result)
      if !res.ok?
        return res
      end

      res = call_03(params, res)
      while !res.ok?
        if res.body["Medical_Select_Flag"] == "True"
          if params["Medical_Select_Information"]
            answer = params["Medical_Select_Information"].find { |i|
              i["Medical_Select"] == res.body["Medical_Select_Information"]["Medical_Select"] && i["Select_Answer"]
            }
          end
          if answer
            res = call_03(params, res, answer)
          else
            return UnselectedError.new(res.raw)
          end
        else
          return res
        end
      end

      call_04(params, res)
    end

    # 診察料返却API（初回接続）
    # http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api1
    # medicalv3req1
    def call_01_for_create(params)
      body = {
        "medicalv3req1" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => params["Patient_ID"],
          "Perform_Date" => params["Perform_Date"],
          "Perform_Time" => params["Perform_Time"],
          "Orca_Uid" => "",
          "Diagnosis_Information" => params["Diagnosis_Information"],
        },
      }
      Response1Result.new(
        orca_api.call("/api21/medicalmodv31", body: body), ignore_medical_warnings(params)
      )
    end

    # 診療内容基本チェックAPI
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api2
    def call_02(params, previous_result)
      res = previous_result
      res_body = res.body
      body = {
        "medicalv3req2" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Perform_Date" => res_body["Perform_Date"],
          "Perform_Time" => res_body["Perform_Time"],
          "Orca_Uid" => res.orca_uid,
          "Diagnosis_Information" => {
            "Department_Code" => params["Diagnosis_Information"]["Department_Code"],
            "Physician_Code" => params["Diagnosis_Information"]["Physician_Code"],
            "Outside_Class" => params["Diagnosis_Information"]["Outside_Class"],
            "Medical_Information" => {
              "Medical_Info" => params["Diagnosis_Information"]["Medical_Information"]["Medical_Info"],
            },
            "HealthInsurance_Information" => res.patient_information["HealthInsurance_Information"],
            "Medical_OffTime" => res_body["Medical_OffTime"]
          }
        }
      }
      body = call_02_for_modify body, res_body, params
      Response2Result.new(
        orca_api.call("/api21/medicalmodv32", body: body), ignore_medical_warnings(params)
      )
    end

    def call_02_for_modify(body, res_body, params)
      if res_body["Invoice_Number"]
        body["medicalv3req2"]["Perform_Time"] = params["Perform_Time"]
        body["medicalv3req2"]["Invoice_Number"] = res_body["Invoice_Number"]
        body["medicalv3req2"]["Patient_Mode"] = "Modify"
        body["medicalv3req2"]["Diagnosis_Information"]["HealthInsurance_Information"] =
          params["Diagnosis_Information"]["HealthInsurance_Information"]
        body["medicalv3req2"]["Diagnosis_Information"]["Medical_OffTime"] =
          params["Diagnosis_Information"]["Medical_Information"]["OffTime"]
      end
      body
    end

    # 診療確認API
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api3
    def call_03(params, previous_result, answer = nil)
      res = previous_result
      res_body = res.body
      body = {
        "medicalv3req2" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Perform_Date" => res_body["Perform_Date"],
          "Perform_Time" => res_body["Perform_Time"],
          "Orca_Uid" => res.orca_uid,
          "Diagnosis_Information" => {
            "Physician_Code" => res_body["Physician_Code"],
          },
        }
      }
      if res.body["Invoice_Number"]
        body["medicalv3req2"]["Patient_Mode"] = "Modify"
        body["medicalv3req2"]["Invoice_Number"] = res.invoice_number
      end
      if answer
        body["medicalv3req2"]["Select_Answer"] = answer["Select_Answer"]
      end
      Response2Result.new(
        orca_api.call("/api21/medicalmodv32", body: body), ignore_medical_warnings(params)
      )
    end

    # 診療確認・請求確認API
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api4
    def call_04(params, previous_result)
      res = previous_result

      can_delete = res.medical_information["Medical_Info"].any? { |i| i["Medical_Delete_Number"] }
      if can_delete && !params["Delete_Number_Info"]
        return EmptyDeleteNumberInfoError.new(res.raw)
      end

      body = {
        "medicalv3req3" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Base_Date" => params["Base_Date"],
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Perform_Date" => res.body["Perform_Date"],
          "Orca_Uid" => res.orca_uid,
          "Medical_Mode" => (can_delete && params["Delete_Number_Info"] ? "1" : nil),
          "Delete_Number_Info" => params["Delete_Number_Info"],
          "Ic_Code" => params["Ic_Code"],
          "Ic_Request_Code" => params["Ic_Request_Code"],
          "Ic_All_Code" => params["Ic_All_Code"],
          "Cd_Information" => params["Cd_Information"],
          "Print_Information" => params["Print_Information"],
        }
      }
      if params["Invoice_Number"]
        body["medicalv3req3"]["Patient_Mode"] = "Modify"
      end
      Response3Result.new(
        orca_api.call("/api21/medicalmodv33", body: body), ignore_medical_warnings(params)
      )
    end

    # 診療登録API
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api5
    def call_05(params, previous_result)
      res = previous_result
      body = {
        "medicalv3req3" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => res.karte_uid,
          "Base_Date" => params["Base_Date"],
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Perform_Date" => res.body["Perform_Date"],
          "Orca_Uid" => res.orca_uid,
          "Ic_Code" => params["Ic_Code"],
          "Ic_Request_Code" => params["Ic_Request_Code"],
          "Ic_All_Code" => params["Ic_All_Code"],
          "Cd_Information" => params["Cd_Information"],
          "Print_Information" => params["Print_Information"],
        }
      }
      if params["Invoice_Number"]
        body["medicalv3req3"]["Patient_Mode"] = "Modify"
      end
      Response3Result.new(
        orca_api.call("/api21/medicalmodv33", body: body), ignore_medical_warnings(params)
      )
    end

    # 診療行為訂正処理
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api7
    def call_01_for_update(params, patient_mode)
      body = {
        "medicalv3req4" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => "",
          "Patient_ID" => params["Patient_ID"],
          "Perform_Date" => params["Perform_Date"],
          "Patient_Mode" => patient_mode,
          "Invoice_Number" => params["Invoice_Number"],
          "Department_Code" => params["Department_Code"],
          "Insurance_Combination_Number" => params["Insurance_Combination_Number"],
          "Sequential_Number" => params["Sequential_Number"],
        },
      }
      ResponseResult.new(
        orca_api.call("/api21/medicalmodv34", body: body), ignore_medical_warnings(params)
      )
    end

    # 診療行為削除処理
    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api6
    def call_02_for_delete(previous_result)
      res = previous_result
      body = {
        "medicalv3req4" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Perform_Date" => res.perform_date,
          "Patient_Mode" => "Delete",
          "Invoice_Number" => res.invoice_number,
          "Department_Code" => res.department_code,
          "Insurance_Combination_Number" => res.health_insurance_information["Insurance_Combination_Number"],
          "Sequential_Number" => res.sequential_number,
          "Select_Answer" => "Ok",
        },
      }
      Result.new(orca_api.call("/api21/medicalmodv34", body: body))
    end

    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api1
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf
    def unlock_for_create(locked_result)
      if locked_result && locked_result.respond_to?(:orca_uid)
        body = {
          "medicalv3req1" => {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Perform_Date" => locked_result.body["Perform_Date"],
            "Orca_Uid" => locked_result.orca_uid,
          }
        }
        orca_api.call("/api21/medicalmodv31", body: body)
        # TODO: エラー処理
      end
    end

    # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/16921#api6
    # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori-overview.data/api21v03.pdf
    def unlock_for_update(locked_result)
      if locked_result && locked_result.respond_to?(:orca_uid)
        body = {
          "medicalv3req4" => {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => locked_result.patient_information["Patient_ID"],
            "Perform_Date" => locked_result.perform_date,
            "Orca_Uid" => locked_result.orca_uid,
          }
        }
        orca_api.call("/api21/medicalmodv34", body: body)
        # TODO: エラー処理
      end
    end
  end
end
