# -*- coding: utf-8 -*-

if ARGV.length < 3
  $stderr.puts(<<-EOS)
Usage:
  check_contraindication.rb <patient_id> <medication_code> <medication_code> [medication_code] ...
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_medical_practice_service

patient_id = ARGV.shift

medical_information = []
while (medication_code = ARGV.shift)
  medical_information << {
    "Medication_Code" => ARGV.shift, # 薬剤コード/9
    # "Medication_Name" => "", # 薬剤名称/80
  }
end

args = {
  "Patient_ID" => patient_id,
  "Perform_Month" => "", # 診療年月/7/未設定はシステム日付
  "Check_Term" => "", # チェック期間/2/未設定はシステム管理の相互作用チェック期間
  "Medical_Information" => medical_information, # チェック薬剤情報/30
}

result = service.check_contraindication(args)
if result.ok?
  print_result(result, "Patient_Information", "Medical_Information")
else
  error(result)
end
