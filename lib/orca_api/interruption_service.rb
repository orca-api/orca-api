require_relative "service"

module OrcaApi
  # 中途終了データを扱うサービスを表現したクラス
  class InterruptionService < Service
    # 中途終了データ一覧の取得
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/medicaltemp.html
    def list(params)
      api_path = "/api01rv2/tmedicalgetv2"
      req_name = "tmedicalgetreq"
      body = {
        req_name => params
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # 中途終了データ詳細の取得（haori）
    # haoriとORCA APIでレスポンスのMedical_Information以下の構造が微妙に異なる
    # 例：
    # * haoriはMedical_Infoが追加されている
    # * haoriはMedication_Info／ORCA APIはMedication_info
    #
    # @see https://www.orcamo.co.jp/api-council/members/standards/?haori_medicalmod#api11
    def detail(params)
      api_path = "/api21/tmedicalmodv2"
      req_name = "tmedicalmodreq"
      body = {
        req_name => {
          "Request_Number" => "01"
        }.merge(params)
      }
      Result.new(orca_api.call(api_path, body: body))
    end

    # 中途終了データの登録
    #     class=01（登録）
    #
    # > データ登録(class=01)で診療データ、病名データ、あるいは両方のデータを登録します。
    #
    # InOut	入外区分(I:入院、 それ以外:入院外)
    # Patient_ID	患者番号	必須
    # Perform_Date	診療日
    # Perform_Time	診療時間
    # Medical_Uid	 	 	変更、削除のみ必須
    # Diagnosis_Information	診療情報
    #   Department_Code 診療科コード 必須
    #   Physician_Code	ドクタコード	10001	必須
    #   HealthInsurance_Information	保険組合せ情報
    #     Insurance_Combination_Number 保険組合せ番号
    #     InsuranceProvider_Class	保険の種類
    #     InsuranceProvider_Number	保険者番号
    #     InsuranceProvider_WholeName	保険の制度名称
    #     HealthInsuredPerson_Symbol	記号
    #     HealthInsuredPerson_Number	番号
    #     HealthInsuredPerson_Continuation	継続区分(1:継続療養、 2:任意継続)
    #     HealthInsuredPerson_Assistance	補助区分(詳細については、「日医標準レセプトソフトデータベーステーブル定義書」を参照して下さい。)
    #     RelationToInsuredPerson	本人家族区分(1:本人、 2:家族)
    #     HealthInsuredPerson_WholeName	被保険者名	日医　太郎
    #     Certificate_StartDate	適用開始日
    #     Certificate_ExpiredDate	適用終了日
    #     PublicInsurance_Information	公費情報(繰り返し4)
    #       PublicInsurance_Class	公費の種類
    #       PublicInsurance_Name	公費の制度名称
    #       PublicInsurer_Number	負担者番号
    #       PublicInsuredPerson_Number	受給者番号
    #       Certificate_IssuedDate	適用開始日
    #       Certificate_ExpiredDate	適用終了日
    #   Medical_Information	診療行為情報(繰り返し40)
    #     Medical_Class	診療種別区分(詳細については、「日医標準レセプトソフトデータベーステーブル定義書」を参照して下さい。)
    #     Medical_Class_Name	診療種別区分名称
    #     Medical_Class_Number	回数、日数
    #     Medication_info	診療内容(繰り返し40)
    #       Medication_Code	診療行為コード
    #       Medication_Name	名称
    #       Medication_Number	数量
    #       Medication_Generic_Flg 一般処方指示(yes：一般名を使用する、no：銘柄指示、以外：日レセの設定指示に従う)
    #       Medication_Continue 継続コメント区分(1：継続コメント)
    #       Medication_Internal_Kinds 内服１種類区分(1：内服１種類)
    #   Disease_Information	病名情報(繰り返し50)
    #     Disease_Code	一連病名コード
    #     Disease_InOut	入外区分(O:外来、I:入院)(半角大文字)
    #     Disease_Name	一連病名名称(全角40文字まで)
    #     Disease_Single	単独病名情報(繰り返し6)
    #       Disease_Single_Code	単独病名コード
    #       Disease_Single_Name	単独病名
    #       Disease_Supplement 病名補足コメント情報
    #       Disease_Scode1 補足コメントコード１
    #       Disease_Scode2 補足コメントコード２
    #       Disease_Scode3 補足コメントコード３
    #       Disease_Sname 補足コメント
    #       Disease_Category	主病フラグ（PD:主病名）
    #       Disease_SuspectedFlag	疑いフラグ
    #       Disease_StartDate	病名開始日
    #       Disease_EndDate	転帰日
    #       Disease_OutCome	転帰区分
    #
    # ##一般名処方について
    # 電子カルテ等から、医薬品に対し一般名指示等をおこないたい場合には、以下の設定により送信して下さい。
    #  ※上記設定が有効となるのは、内服、外用、頓服のみです。但し、加算には関係ありませんが、注射でも一般名記載指示を許可します。
    # Medication_Generic_Flg : yes   一般名を使用する
    #                        : no    銘柄指示
    #                        : 以外  日レセの設定指示に従う
    #  又、医薬品の直下にMedication_Codeにより日レセのシステム予約コード（一般名記載：099209908）等の設定も可能ですが、Medication_Generic_Flgによる指示がある場合は、そちらを優先します。
    #
    # @see https://www.orca.med.or.jp/receipt/tec/api/medicalmod.html
    def create(params)
      body = {
        "medicalreq" => params
      }
      Result.new(call_with_class_number("01", body))
    end

    # 中途終了データの削除
    #     class=02（削除）
    #
    # > データ削除(class=02)、データ変更(class=03)では診療データのみを対象とするため、病名データを設定しても無効となります。
    # @see https://www.orca.med.or.jp/receipt/tec/api/medicalmod.html
    def destroy(params)
      body = {
        "medicalreq" => params
      }
      Result.new(call_with_class_number("02", body))
    end

    # 中途終了データの変更
    #     class=03（変更）
    #
    # > データ削除(class=02)、データ変更(class=03)では診療データのみを対象とするため、病名データを設定しても無効となります。
    # @see https://www.orca.med.or.jp/receipt/tec/api/medicalmod.html
    def update(params)
      body = {
        "medicalreq" => params
      }
      Result.new(call_with_class_number("03", body))
    end

    # 中途終了データの外来追加
    #     class=04 (外来追加)
    #
    # ##外来での中途データ追記機能(外来追加)について
    #
    # 患者番号、診療日付、診療科、保険組合せが一致する中途データに診療内容を追加します。
    # ドクターコードが一致しない時、中途データが診療行為の中途終了登録で作成したデータの場合、中途データの最大剤番号が最大値(99999999)の場合はエラーになります。
    # 外来データ登録時(class=04)のレスポンスにデータ追記登録を行いuid(Medical_Uid)を設定し返却します。（新規時はそのまま登録）
    # ※入院データの場合、このclassは使用できません。
    # データ削除時(class=02)のリクエストは入院と同様の仕様になります。
    # 診察料の二重チェックおよび送信途中に日レセで展開された場合のチェックは行えないため運用で対応してください。
    # 初診・再診料等の診察料が１件目の１行目になるように送信します（診察料に含まれる時間外コードはこれ以降に送信されたものに対してのみ反映されそれ以前のものには反映されないため）。
    # それ以外の場所に設定した場合は正しい処理ができないことがあります。また、診察料は複数送信しないで下さい。
    # ※展開時に診察料を自動発生しない場合の注意です。
    # @see https://www.orca.med.or.jp/receipt/tec/api/medicalmod.html
    def out_create(params)
      body = {
        "medicalreq" => params
      }
      Result.new(call_with_class_number("04", body))
    end

    private

    def call_with_class_number(class_number, body)
      orca_api.call(
        "/api21/medicalmodv2",
        params: { class: class_number },
        body: body
      )
    end
  end
end
