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
  "Special_Notes_Information" => { # 特記事項
    "Special_Notes_Mode" => mode, # 処理区分/6/Modify：更新、Delete：削除　※２
    "Special_Notes_Info" => [ # 50
      {
        "Special_Notes_InOut" => "2", # 入外区分/1/※４
        "Special_Notes_Receipt_Code" => "11", # レセ電区分/2/※５
        "Special_Notes_Receipt_Code_Name" => "", # レセ電区分名称（紙レセプト）/12/※５
        "Special_Notes_StartDate" => "2017-09", # 開始年月/7/必須
        "Special_Notes_ExpiredDate" => "2017-10", # 終了年月/7
      },
    ],
  }
}
# ※２　所得者２、所得者１、旧姓履歴、特記事項、患者個別情報毎に、更新（Modify）、削除（Delete）の指定を行います。
# 　　　更新（Modify）は処理単位毎に一括削除・一括登録を行います。１レコード毎の更新はできません。
# 　　　削除（Delete）は処理単位毎に一括削除します。
# ※４　0 ：入院・入院外
# 　　　1：入院
# 　　　2：入院外
# ※５　レセ電コードがあれば、レセ電区分名称を編集します。存在しないレセ電コードであれば、レセ電区分名称（紙レセプト）は必須です。
# 　　　　レセ電区分名称（紙レセプト）のみの設定も可能です。

result = patient_service.update_special_notes(patient_id, params)
if result.ok?
  pp result.patient_information
  pp result["Special_Notes_Information"]
else
  error(result)
end
