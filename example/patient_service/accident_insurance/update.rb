# -*- coding: utf-8 -*-

if ![2, 4].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  upadte.rb <patient_id> <mode> [insurance_id] [public_insurance_id]
    mode: new, modify, delete
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
mode, insurance_id, public_insurance_id =
  (case (s = ARGV.shift.downcase)
   when "new"
     ["New", "0", "0"]
   when "modify"
     ["Modify", ARGV.shift, ARGV.shift]
   when "delete"
     ["Delete", ARGV.shift, ARGV.shift]
   else
     raise "mode is not new or modify or delete: #{s}"
   end)

today = Time.now
params = {
  "Accident_Insurance_Information" => { # 労災保険情報 ※2
    "Accident_Insurance_Info" => [ # 40
      {
        "Accident_Mode" => mode, # 処理区分/6/New：新規、Modify：更新、Delete：削除　※８
        "InsuranceProvider_Id" => insurance_id, # 保険ＩＤ/10/※３
        "PublicInsurance_Id" => public_insurance_id, # 公費ＩＤ/10/※３
        "InsuranceProvider_Class" => "971", # 保険の種類/3/※４
        "InsuranceProvider_WholeName" => "労災保険", # 保険の制度名称/20
        "Accident_Insurance" => "1", # 労災保険区分/1/必須　※４
        "Accident_Insurance_WholeName" => "短期給付", # 労災保険名称/50
        "Disease_Location" => (mode == "New" ? "肘" : "肩腰"), # 傷病の部位/100/全角５０文字
        "Disease_Date" => today.strftime("%Y-%m-%d"), # 傷病年月日/10/必須
        "Accident_StartDate" => today.strftime("%Y-%m-%d"), # 療養開始日/10/必須
        "Accident_ExpiredDate" => "", # 療養終了日/10/省略可（９９９９９９９９）
        "Accident_Insurance_Number" => "12345678901", # 労働保険番号/14/※５
        "PensionCertificate_Number" => "", # 年金証書番号/9/
        "Accident_Class" => "1", # 災害区分/1/１：業務中の災害、２：通勤途上の災害
        "Labor_Station_Code" => "12349", # 労働基準監督署コード/5
        "Accident_Continuous" => "1", # 新規継続区分/1/１：初診、５：継続、７：再発
        "Outcome_Reason" => "3", # 転帰事由/1
        "Limbs_Exception" => "0", # 四肢特例区分/1/０：なし、１：四肢、２：手指
        "Liability_Office_Information" => { # 事業所情報
          "L_WholeName" => "松江共同", # 事業所名称/80
          "Prefecture_Information" => { # 所在地都道府県
            "P_WholeName" => "島根", # 都道府県名称/20
            "P_Class" => "4", # 都道府県区分/1/：都、２：道、３：府、４：県
            "P_Class_Name" => "県" # 都道府県区分名称/2
          },
          "City_Information" => { # 所在地郡市
            "C_WholeName" => "松江", # 郡市区名称/80
            "C_Class" => "2", # 郡市区区分/1/１：郡、２：市、３：区
            "C_Class_Name" => "市" # 郡市区区分名称/2/全角１文字
          },
          "Accident_Base_Month" => today.strftime("%Y-%m"), # 労災レセ回数記載 基準年月/7/省略時　療養開始年月
          "Accident_Receipt_Count" => "001", # 労災レセ回数記載 回数/3/省略時　１
          "Liability_Insurance" => "", # 自賠責請求区分/1
          "Liability_Insurance_Office_Name" => "", # 自賠責保険会社名/80
          "Liability_Physician_Code" => "", # 自賠責担当医コード/5
          "Liability_Class" => "", # 自賠責点数算定区分/1
          "PersonalHealthRecord_Number" => "", # アフターケア 健康管理手帳番号/13
          "Damage_Class" => { # アフターケア 損傷区分
            "D_Code" => "" # 損傷区分/3
          },
          "Third_Party_Supply" => "", # 第三者行為 現物支給区分/1/１：対象外、２：対象
          "Third_Party_Report" => "", # 第三者行為 特記事項区分/1/１：「１０第三」記載有、２：「１０第三」記載無
        }
      }
    ],
  }
}
# ※2　リクエスト番号＝０１　で返却した労災自賠責保険情報を元に、リクエスト番号＝０２で送信します
# 　　　変更しない労災自賠責保険の送信は必須ではありません。
# ※３　新規（New）はゼロ、更新（Modify）、削除（Delete）はリクエスト番号＝０１　で返却した保険ＩＤ，公費ＩＤを設定
# 　　　第三者行為以外は公費ＩＤ＝ゼロ、第三者行為は保険ＩＤ＝ゼロとなります。
# ＃労災自賠責保険は重複登録可能です。同じ保険内容を複数登録することも可能ですので、注意して下さい。
#
# ※4　保険区分から保険の種類を決定します。保険の種類を変更した時は、ワーニングを返却します。
# 　　　保険区分　１：短期給付、２：傷病年金、３：アフターケア、４：自賠責保険、５：公務災害、６：第三者行為
#
# ※５　以下の項目は、保険により必須項目・設定項目が違います。
# 　　　設定不要な項目を送信しても破棄しますが、数値チェックなどの項目値基本チェックは行います。
#
# ※8 今回変更なしは空白とします。

result = patient_service.update_accident_insurance(patient_id, params)
if result.ok?
  pp result.patient_information
  pp result["Accident_Insurance_Information"]
else
  error(result)
end
