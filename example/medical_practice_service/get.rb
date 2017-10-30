# -*- coding: utf-8 -*-

if ![3].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  get.rb <patient_id> <perform_date> <invoice_number>
    perform_date: YYYY-mm-dd
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_medical_practice_service

patient_id = ARGV.shift
perform_date = ARGV.shift
invoice_number = ARGV.shift

args = {
  "Patient_ID" => patient_id, # 患者番号/20/必須
  "Perform_Date" => perform_date, # 診療日付/10/必須
  "Invoice_Number" => invoice_number, # 伝票番号/7/※2
  "Department_Code" => "", # 診療科/1/※２
  "Insurance_Combination_Number" => "", # 保険組合せ番号/4/※２
  "Sequential_Number" => "", # 連番/1/※２
}
# ※２　伝票番号を優先とする。
# 　　　伝票番号がない時のみ、診療科・保険組合せ・連番から受診履歴を決定する。
# 　　　連番の未設定は１とする。

result = service.get(args)
if result.ok?
  print_result(result)
else
  error(result)
end
