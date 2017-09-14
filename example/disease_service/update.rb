# -*- coding: utf-8 -*-
require_relative "../common"

disease_service = @orca_api.new_disease_service

params = {
  "Patient_ID" => ARGV.shift, # 患者番号/20/必須
  "Base_Month" => "", # 基準月/7/（空白時はシステム日の属する月）。基準月に有効な病名でリクエスト内に設定されていない日レセの病名情報を返却する。(日レセにのみ存在する病名)
  "Perform_Date" => "", # 実施年月日/10
  "Perform_Time" => "", # 実施時間/8
  "Diagnosis_Information" => { # 診療科情報
    "Department_Code" => "01", # 診療科/2
  },
  "Disease_Information" => [ # 病名情報/50/必須
    {
      "Disease_Insurance_Class" => "05", # 保険区分/1/(１：医保(自費)以外、１以外：医保(自費))
      "Disease_Code" => "", # 一連病名コード/50/必須　※１
      "Disease_Name" => "", # 一連病名/80/必須　※１
      "Disease_Single" => [ # 単独病名情報/6/必須
        {
          "Disease_Single_Code" => "5319009", # 単独病名コード/7
          "Disease_Single_Name" => "胃潰瘍", # 単独病名/20
        },
      ],
      "Disease_Supplement" => { # 補足コメント情報/※２
        "Disease_Scode1" => "", # 補足コメントコード１/10
        "Disease_Scode2" => "", # 補足コメントコード２/10
        "Disease_Scode3" => "", # 補足コメントコード３/10
        "Disease_Sname" => "右膝", # 補足コメント/40
      },
      "Disease_InOut" => "", # 入外区分（I：入院、O：入院外、空白：入外）/1
      "Disease_Category" => "", # 主病フラグ（PD：主疾患）/2
      "Disease_SuspectedFlag" => "", # 疑いフラグ（S：疑い）/1
      "Disease_StartDate" => "2017-07-15", # 開始日/10/必須
      "Disease_EndDate" => "", # 転帰日/10
      "Disease_OutCome" => "", # 転帰区分/2/※６
      "Disease_Karte_Name" => "", # カルテ病名/80/※３
      "Disease_Class" => "", # 疾患区分（０３：皮膚科特定疾患指導管理料（１）、０４：皮膚科特定疾患指導管理料（２）、０５：:特定疾患療養管理料、０７：てんかん指導料、０８：特定疾患療養管理料又はてんかん指導料、０９：難病外来指導管理料）/4/※４
      "Insurance_Combination_Number" => "", # 保険組合せ番号/4/労災、公害、自賠責、第三者行為は必須　　　 ※５
      "Disease_Receipt_Print" => "", # レセプト表示（１：表示しない）/4/※３
      "Disease_Receipt_Print_Period" => "", # レセプト表示期間（００～９９）/4/※３
      "Insurance_Disease" => "False", # 保険病名（１：保険病名）/4/※３
      "Discharge_Certificate" => "", # 退院証明書（空白または０：記載しない、１：記載する）/4/※３
      "Main_Disease_Class" => "", # 原疾患区分（０１：原疾患ア、０２：原疾患イ、０３：原疾患ウ、０４：原疾患エ、０５：原疾患オ）/4/※３
      "Sub_Disease_Class" => "", # 合併症区分（０１：アの合併症、０２：イの合併症、０３：ウの合併症、０４：エの合併症、０５：オの合併症）/4/※３
    },
    {
      "Department_Code" => "01",
      "Disease_Name" => "両変形性膝関節症",
      "Disease_Single" => [
        {
          "Disease_Single_Code" => "ZZZ2057",
          "Disease_Single_Name" => "両",
        },
        {
          "Disease_Single_Code" => "7153018",
          "Disease_Single_Name" => "変形性膝関節症",
        },
      ],
      "Disease_StartDate" => "2017-06-01",
      #"Disease_OutCome" => "O", # 削除
      "Insurance_Disease" => "False",
    },
    {
      "Department_Code" => "01",
      "Disease_Name" => "慢性心不全の疑い",
      "Disease_Single" => [
        {
          "Disease_Single_Code" => "4289018",
          "Disease_Single_Name" => "慢性心不全",
        },
        {
          "Disease_Single_Code" => "ZZZ8002",
          "Disease_Single_Name" => "の疑い",
        },
      ],
      "Disease_SuspectedFlag" => "S",
      "Disease_StartDate" => "2014-08-01",
      #"Disease_OutCome" => "O", # 削除
      "Disease_Class" => "05",
      "Insurance_Disease" => "False",
    },
    {
      "Department_Code" => "01",
      "Disease_Name" => "食思不振",
      "Disease_Code" => "0000999",
      "Disease_StartDate" => "2012-10-23",
      #"Disease_OutCome" => "O", # 削除
      "Insurance_Disease" => "False",
    },
  ],
}
# ※１：単独病名か一連病名のいずれかの設定が必要。両方に設定がある場合は単独病名を優先する。
# 　　　病名コード、病名の両方に設定がある場合は病名コードを優先する。
# ※２：補足コメントコード、補足コメントの両方に設定がある場合は補足コメントコードを優先する。
# ※３：「None」が設定してある場合、新規時は初期値を設定、更新(削除)時は更新(削除)対象としない。
# ※４：「None」が設定してある場合、新規時は初期値を設定、更新時は更新対象としない。
# 　　　「Auto」が設定してある場合、病名コードまたは病名から自動判定した値を設定（なければ空白と同様）。
# ※５：「None」が設定してある場合、新規時は初期値を設定、更新時は更新対象としない。
# 　　　設定された保険組合せ番号が削除分の場合、新規または保険組合せ番号の更新時はエラーとする。
# 　　　Disease_Insurance_Classが「１」のとき、未設定または「None」はエラーとする。
# ※６：転帰区分の取り扱いについては日レセの転帰区分にあわせて以下のように置き換える。
# 　　　　O：削除　　　　　疑いフラグ、開始日、病名、補足コメント、転帰日、入外区分、保険組合せ番号等完全一致したものに対し、削除フラグを設定する。
# 　　　　D：死亡　　　　　２（死亡）
# 　　　　F：完治　　　　　１（治ゆ）
# 　　　　N：不変　　　　　３（中止）
# 　　　　R：軽快　　　　　３（中止）
# 　　　　S：後遺症残　　　３（中止）
# 　　　　U：不明　　　　　３（中止）
# 　　　　W：悪化　　　　　３（中止）
# 　　　　上記以外　　　　 １（治ゆ）
# ※システム管理「9000 CLAIM」の集約、同期は対応しない。
# ※「の疑い」(コードでの設定も同様)は、該当病名に対する更新処理となります。
# 　胃炎に対し「胃炎の疑い」を送信した場合、胃炎を胃炎の疑いとして更新します。
# 　胃炎の疑いに対し、胃炎を送信した場合、胃炎の疑いを胃炎として更新します。 

result = disease_service.update(params)
if result.ok?
  pp result.body
else
  error(result)
end
