# -*- coding: utf-8 -*-

if ![3].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  list.rb <patient_id> <information_class> <start_date>
    information_class: 1 or 2 or 3
    start_date: YYYY-mm-dd
  EOS
  exit(1)
end

require "time"
require_relative "../common"

income_service = @orca_api.new_income_service

patient_id = ARGV.shift
information_class = ARGV.shift
start_date = Date.parse(ARGV.shift)

args = {
  "Patient_ID" => patient_id, # 患者番号/必須/20
  "Information_Class" => information_class, # 請求一覧指示区分/1:指定した期間内の請求一覧、2:指定した期間内の未収（過入）金のある請求一覧、3:指定した期間内に入返金が行われた請求一覧/任意/1/未設定時の初期値は"1"
  "Start_Date" => start_date.strftime("%Y-%m-%d"), # 診療日の期間指定開始日/必須（請求一覧指示区分="3"の場合に設定）/10
  "End_Date" => "", # 診療日の期間指定終了日/任意（請求一覧指示区分="3"の場合に設定）/10/未設定時の初期値は"9999-12-31"
  "Start_Month" => start_date.strftime("%Y-%m"), # 診療月の期間指定開始月/必須（請求一覧指示区分="1"、"2"の場合に設定）/7
  "End_Month" => "", # 診療月の期間指定終了月/任意（請求一覧指示区分="1"、"2"の場合に設定）/7/未設定時の初期値は"9999-12"
  "Sort_Key" => { # ソートキー
    "Key_Class" => "", # 項目/請求一覧指示区分＝1（請求一覧）の場合、1:診療年月、入外区分、伝票番号、2:診療日。請求一覧指示区分＝2（未収一覧）または請求一覧指示区分＝3（入返金一覧）の場合、1:伝票発行日、2:診療日/任意/1/未設定時の初期値は"1"
    "Order_Class" => "", # 並び順区分/1:昇順、2:降順/任意/1/未設定時の初期値は"1"
  }
}
result = income_service.list(args)
if result.ok?
  print_result(result, "Income_Information", "Unpaid_Money_Total_Information")
else
  error(result)
end
