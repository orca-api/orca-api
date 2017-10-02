# -*- coding: utf-8 -*-

if ![2, 4].include?(ARGV.length)
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
  "Maiden_Information" => { # 旧姓履歴
    "Maiden_Mode" => mode, # 処理区分/6/Modify：更新、Delete：削除　※２
    "Maiden_Info" => [ # 20
      {
        "Maiden_Change_Date" => "2017-09-01", # 変更日付/10/必須
        "WholeName_inKana" => "キュウセイ　シメイ", # 旧姓カナ氏名/100
        "WholeName" => "旧姓　氏名", # 旧姓氏名/100
        "NickName" => "にっくねーむ", # 旧姓通称名/100
      },
    ],
  }
}
# ※２　所得者２、所得者１、旧姓履歴、特記事項、患者個別情報毎に、更新（Modify）、削除（Delete）の指定を行います。
# 　　　更新（Modify）は処理単位毎に一括削除・一括登録を行います。１レコード毎の更新はできません。
# 　　　削除（Delete）は処理単位毎に一括削除します。

result = patient_service.update_maiden(patient_id, params)
if result.ok?
  pp result.patient_information
  pp result["Maiden_Information"]
else
  error(result)
end
