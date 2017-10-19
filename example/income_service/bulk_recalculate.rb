# -*- coding: utf-8 -*-

if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  bulk_recalculate.rb <patient_id> <perform_month>
    perform_month: YYYY-mm
  EOS
  exit(1)
end

require_relative "../common"

income_service = @orca_api.new_income_service

patient_id = ARGV.shift
perform_month = ARGV.shift

args = {
  "Patient_ID" => patient_id, # 患者番号/必須/20
  "Perform_Month" => perform_month, # 診療年月/必須/7
  "Processing_Date" => "", # 処理日/任意/10/未設定時の初期値はシステム日付（実際の処理日）
  "Processing_Time" => "", # 処理時刻/任意/8/未設定時の初期値はシステム時刻（実際の処理時刻）
}
result = income_service.bulk_recalculate(args)
if result.ok?
  print_result(result)
else
  error(result)
end
