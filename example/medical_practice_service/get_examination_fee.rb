# -*- coding: utf-8 -*-

if ![5].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  get_examination_fee.rb <patient_id> <department_code> <physician_code> <insurance_combination_number> <doctors_fee>
    doctors_fee: 01: 初診, 02: 再診, 03: 電話再診, 09: 診察料なし
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_medical_practice_service

patient_id = ARGV.shift
department_code = ARGV.shift
physician_code = ARGV.shift
insurance_combination_number = ARGV.shift
doctors_fee = ARGV.shift

args = {
  "Patient_ID" => patient_id, # 患者番号/20/必須
  "Perform_Date" => "", # 診療日付/10/未設定はシステム日付
  "Perform_Time" => "", # 診療時間/8/未使用
  "Diagnosis_Information" => { # 送信内容
  "Department_Code" => department_code, # 診療科/2/必須
  "Physician_Code" => physician_code, # ドクターコード/5
  "HealthInsurance_Information" => { # 保険情報/※１
      "Insurance_Combination_Number" => insurance_combination_number, # 保険組合せ番号/4/指定があれば優先
      "InsuranceProvider_Class" => "", # 保険の種類/3
      "InsuranceProvider_Number" => "", # 保険者番号/8
      "InsuranceProvider_WholeName" => "", # 保険の制度名称/20
      "HealthInsuredPerson_Symbol" => "", # 記号/80
      "HealthInsuredPerson_Number" => "", # 番号/80
      "HealthInsuredPerson_Continuation" => "", # 継続区分/1
      "HealthInsuredPerson_Assistance" => "", # 補助区分/1
      "RelationToInsuredPerson" => "", # 本人家族区分/1
      "HealthInsuredPerson_WholeName" => "", # 被保険者名/100
      "Certificate_StartDate" => "", # 適用開始日/10
      "Certificate_ExpiredDate" => "", # 適用終了日/10
      "PublicInsurance_Information" => { # 公費情報　（４）/4
        "PublicInsurance_Class" => "", # 公費の種類/3
        "PublicInsurance_Name" => "", # 公費の制度名称/20
        "PublicInsurer_Number" => "", # 負担者番号/8
        "PublicInsuredPerson_Number" => "", # 受給者番号/20
        "Certificate_IssuedDate" => "", # 適用開始日/10
        "Certificate_ExpiredDate" => "", # 適用終了日/10
      }
    },
    "Medical_Information" => { # 診療送信内容
      "OffTime" => "0", # 時間外区分/1/外来時間外区分（０から８）とする（環境設定の外来時間外区分）
      "Doctors_Fee" => doctors_fee, # 診察料区分/2/※２
      "Medical_Class" => "", # 診療種別区分/3/診察料コードの診療区分
      "Medical_Class_Name" => "", # 診療種別区分名称/40
      "Medication_Info" => { # 診療行為
        "Medication_Code" => "", # 診療コード/9/診察料コード　※３
        "Medication_Name" => "", # 名称/80
      }
    },
  },
}
# ※１　保険組合せ　又は　保険・公費から保険組合せを決定
# 　　　包括分入力（保険組合せ＝９９９９、保険の種類＝９９）
# 　　　診察料区分（Doctors_Fee）＝０９　は省略可
# ※２　０１＝初診、０２＝再診、０３＝電話再診、０９＝診察料なし
# ※３　コードが使用できるかのチェックを行う。
# 　　　診察料区分の設定がない時のみチェックを行う。

result = service.get_examination_fee(args)
if result.ok?
  print_result(result)
else
  error(result)
end
