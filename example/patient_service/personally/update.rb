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
  "Personally_Information" => { # 患者個別情報
    "Personally_Mode" => mode, # 処理区分/6/Modify：更新、Delete：削除　※２
    "Personally_Info" => {
      "Birth_Weight" => "3800", # 出生時体重/4
      "Community_Disease" => [ # 地域包括診療対象疾病/4/※６
        {
          "Target_Disease" => "True", # 地域包括診療対象(高血圧症)/5/※７
        },
        {
          "Target_Disease" => "False", # 地域包括診療対象(糖尿病)/5/※７
        },
        {
          "Target_Disease" => "True", # 地域包括診療対象(脂質異常症)/5/※７
        },
        {
          "Target_Disease" => "False", # 地域包括診療対象(認知症)/5/※７
        },
      ],
      "Community_Disease2" => "True", # 認知症地域包括診療/5/※７
      "Community_Disease3" => "False", # 小児かかりつけ診療/5/※７
    },
  }
}
# ※６　テーブルの（１）　高血圧症、（２）糖尿病、（３）脂質異常症、（４）認知症
# ※７　True（対象）、False（対象外）

result = patient_service.update_personally(patient_id, params)
if result.ok?
  pp result.patient_information
  pp result["Personally_Information"]
else
  error(result)
end
