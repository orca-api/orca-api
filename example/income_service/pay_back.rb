# -*- coding: utf-8 -*-

if ![3].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  pay_back.rb <patient_id> <in_out> <invoice_number>
    in_out: i or o
  EOS
  exit(1)
end

require_relative "../common"

income_service = @orca_api.new_income_service

patient_id = ARGV.shift
in_out = ARGV.shift.upcase
invoice_number = ARGV.shift

args = {
  "Patient_ID" => patient_id, # 患者番号/必須/20
  "InOut" => in_out, # 入外区分、I:入院/O:外来/必須/1
  "Invoice_Number" => invoice_number, # 伝票番号/必須/7
  "Processing_Date" => "", # 処理日/任意/10/未設定時の初期値はシステム日付（実際の処理日）
  "Processing_Time" => "", # 処理時刻/任意/8/未設定時の初期値はシステム時刻（実際の処理時刻）
}
result = income_service.pay_back(args)
if result.ok?
  print_result(result)
else
  error(result)
end
