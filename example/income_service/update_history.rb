# -*- coding: utf-8 -*-

if ![5].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  update_history.rb <patient_id> <in_out> <invoice_number> <history_number> <ic_money>
    in_out: i or o
  EOS
  exit(1)
end

require_relative "../common"

income_service = @orca_api.new_income_service

patient_id = ARGV.shift
in_out = ARGV.shift.upcase
invoice_number = ARGV.shift
history_number = ARGV.shift
ic_money = ARGV.shift

args = {
  "Patient_ID" => patient_id, # 患者番号/必須/20
  "InOut" => in_out, # 入外区分、I:入院/O:外来/必須/1
  "Invoice_Number" => invoice_number, # 伝票番号/必須/7
  "History_Number" => history_number, # 明細番号/必須/2
  "Processing_Date" => "", # 処理日/任意/10/未設定時は変更なし
  "Processing_Time" => "", # 処理時刻/任意/8/未設定時は変更なし
  "Ad_Money1" => "", # 調整金１（明細の状態区分が"1","3","8","9"の場合に設定可能。但し、請求取消、後は設定不可）/任意/10/未設定時は変更なし
  "Ad_Money2" => "", # 調整金２（明細の状態区分が"1","3","8","9"の場合に設定可能。但し、請求取消、後は設定不可）/任意/10/未設定時は変更なし
  "Ic_Money" => ic_money, # 入金額/任意/10/未設定時は変更なし、状態区分が"4","6"の場合、負の値を設定
  "Ic_Code" => "", # 入金方法、システム管理［1041 入金方法情報］より設定/任意/2/未設定時は変更なし
}
result = income_service.update_history(args)
if result.ok?
  print_result(result)
else
  error(result)
end
