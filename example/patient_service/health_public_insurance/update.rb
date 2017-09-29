# -*- coding: utf-8 -*-

if ![3, 4].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  upadte.rb <patient_id> <"health" or "public"> <mode> [insurance_id]
    mode: new, modify, delete
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
health_or_public = ARGV.shift
mode, insurance_id =
  (case (s = ARGV.shift.downcase)
   when "new"
     ["New", "0"]
   when "modify"
     ["Modify", ARGV.shift]
   when "delete"
     ["Delete", ARGV.shift]
   else
     raise "mode is not new or modify or delete: #{s}"
   end)

template = {
  "HealthInsurance_Information" => { # 保険情報
    "HealthInsurance_Info" => [ # 保険情報/40
      {
        "InsuranceProvider_Mode" => "", # 処理区分/6/New 　：新規、Modify：更新、Delete：削除　　　※８
        "InsuranceProvider_Id" => "", # 保険ＩＤ/10/※３
        "InsuranceProvider_Class" => "039", # 保険の種類/3/※５
        "InsuranceProvider_Number" => "39322011", # 保険者番号/8/※５
        "InsuranceProvider_WholeName" => "後期高齢者", # 保険の制度名称/20
        "HealthInsuredPerson_Symbol" => "", # 記号/80/全角２０文字
        "HealthInsuredPerson_Number" => "１２３４５６", # 番号/80/全角２０文字
        "HealthInsuredPerson_Continuation" => "", # 継続区分/1
        "HealthInsuredPerson_Assistance" => "1", # 補助区分/1/※6
        "RelationToInsuredPerson" => "1", # 本人家族区分/1/必須
        "HealthInsuredPerson_WholeName" => "東京　太郎", # 被保険者名/100/全角２５文字
        "Certificate_StartDate" => "2017-01-01", # 適用開始日/10/省略可（処理日付）
        "Certificate_ExpiredDate" => "2017-12-31", # 適用終了日/10/省略可（９９９９９９９９）
        "Certificate_GetDate" => "2017-01-03", # 資格取得日/10
        "Certificate_CheckDate" => "2017-07-26", # 確認日付/10/※４
        "Rate_Class" => "", # 高齢者負担区分/1/未使用
      },
    ],
  },
  "PublicInsurance_Information" => { # 公費情報
    "PublicInsurance_Info" => [ #公費情報/60
      {
        "PublicInsurance_Mode" => "", # 処理区分/6/New 　：新規、Modify：更新、Delete：削除　　　※８
        "PublicInsurance_Id" => "", # 公費ＩＤ/10/※３
        "PublicInsurance_Class" => "968", # 公費の種類/3/※７
        "PublicInsurance_Name" => "後期該当", # 公費の制度名称/20
        "PublicInsurer_Number" => "", # 負担者番号/8
        "PublicInsuredPerson_Number" => "", # 受給者番号/20
        "Certificate_IssuedDate" => "2017-01-01", # 適用開始日/10/省略可（処理日付）
        "Certificate_ExpiredDate" => "2017-12-31", # 適用終了日/10/省略可（９９９９９９９９）
        "Certificate_CheckDate" => "2017-07-28", # 確認日付/10/※４
      },
    ],
  },
}
# ※３　新規（New）はゼロ、更新（Modify）、削除（Delete）はリクエスト番号＝０１　で返却した保険ＩＤ，公費ＩＤを設定
# ※４　新規・更新の時、未設定なら処理日付（基準日の設定があれば基準日＝処理日付）
# ※５　保険者番号があれば保険者番号から保険の種類を決定します。保険の種類を変更した時は、ワーニングを返却します。
# 　　　保険者番号・保険の種類はどちらかが必須となります。
# ※６　未設定の時、保険の種類・開始日から設定します。（オンラインの初期表示と同じ補助区分）
# 　　　使用できない補助区分を送信した場合も正しい補助区分に変更し、ワーニングを返却します。
# ※７　未設定の時、負担者番号から公費の種類を決定します
# ※８ 今回変更なしは空白とします。

params = {}
case health_or_public
when "health"
  params["HealthInsurance_Information"] = template["HealthInsurance_Information"]
  info = params["HealthInsurance_Information"]["HealthInsurance_Info"][0]
  info["InsuranceProvider_Mode"] = mode
  info["InsuranceProvider_Id"] = insurance_id
when "public"
  params["PublicInsurance_Information"] = template["PublicInsurance_Information"]
  info = params["PublicInsurance_Information"]["PublicInsurance_Info"][0]
  info["PublicInsurance_Mode"] = mode
  info["PublicInsurance_Id"] = insurance_id
else
  fail "health or public: #{health_or_public}"
end

result = patient_service.update_health_public_insurance(patient_id, params)
if result.ok?
  pp result.patient_information
  pp result.health_public_insurance
else
  error(result)
end
