# -*- coding: utf-8 -*-

if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  reprint.rb <patient_id> <in_out> <invoice_number> <history_number> <print_invoice_receipt_class> <print_statement_class>
  EOS
  exit(1)
end

require_relative "../common"

income_service = @orca_api.new_income_service

patient_id = ARGV.shift
in_out = ARGV.shift.upcase
invoice_number = ARGV.shift
history_number = ARGV.shift
print_invoice_receipt_class = ARGV.shift
print_statement_class = ARGV.shift

args = {
  "Patient_ID" => patient_id, # 患者番号/必須/20
  "InOut" => in_out, # 入外区分、I:入院/O:外来/必須/1
  "Invoice_Number" => invoice_number, # 伝票番号/必須/7
  "History_Number" => history_number, # 明細番号/任意/2
  "Print_Information" => { # 印刷情報
    "Print_Invoice_Receipt_Class" => print_invoice_receipt_class, # 請求書兼領収書印刷区分、0:発行なし/1:発行あり/任意/1
    "Print_Statement_Class" => print_statement_class, # 診療費明細書印刷区分、0:発行なし/1:発行あり/任意/1
  }
}
result = income_service.reprint(args)
if result.ok?
  print_result(result)
else
  error(result)
end