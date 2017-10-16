# -*- coding: utf-8 -*-

if ![3].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  update.rb <patient_id> <in_out> <invoice_number>
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
}
result = income_service.get(args)
if result.ok?
  print_result(result)
else
  error(result)
end
