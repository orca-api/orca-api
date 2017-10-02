# -*- coding: utf-8 -*-

if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  upadte.rb <patient_id> <mode>
    mode: modify, delete
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
mode =
  (case (s = ARGV.shift.downcase)
   when "modify"
     "Modify"
   when "delete"
     "Delete"
   else
     raise "mode is not modify or delete: #{s}"
   end)

params = {
  "Income_Information" => { # 低所得者２情報（低所得者履歴）
    "Income_Mode" => mode, # 処理区分/6/Modify：更新、Delete：削除　※２
    "Income_Info" => [ # 20
      {
        "Income_StartDate" => "2017-09-01", # 認定開始日/10/必須
        "Income_ExpiredDate" => "9999-12-31", # 認定終了日/10
        "Income_Reduction_Date" => "2017-09-30", # 標準負担額減額開始日/10
        "Income_Long_Period_Date" => "", # 長期入院該当年月日/10
        "Income_Certificate_Code" => "0", # 認定範囲区分/1/※３
        "Income_Boundary_Code" => "1", # 境界層該当区分/1/0:境界層非該当、1:境界層該当
      },
    ],
  }
}
# ※２　所得者２、所得者１、旧姓履歴、特記事項、患者個別情報毎に、更新（Modify）、削除（Delete）の指定を行います。
# 　　　更新（Modify）は処理単位毎に一括削除・一括登録を行います。１レコード毎の更新はできません。
# 　　　削除（Delete）は処理単位毎に一括削除します。
# ※３　0 ：すべて対象
# 　　　 1：地方公費は対象外
# 　　　 2：地方公費のみ対象
# 　　　 3：食事標準負担額のみ対象
# 　　　 4：地方公費＋食事標準負担額対象

result = patient_service.update_income(patient_id, params)
if result.ok?
  pp result.patient_information
  pp result["Income_Information"]
else
  error(result)
end
