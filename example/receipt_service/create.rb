if ![4, 5].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  create.rb all <Perform_Month> <InOut> <Print_Mode> <Submission_Mode>
  create.rb <Patient_ID>:<Patient_Perform_Month>[,<Patient_ID>:<Patient_Perform_Month>] <InOut> <Print_Mode> <Submission_Mode>
    Perform_Month: YYYY-mm-dd
    InOut: i or o
    Print_Mode: check or normal
    Submission_Mode: 01 or 02 or 03 or 04 or 05 or 06 or 07 or 08 or 09
      01:医保, 02:全件, 03:社保, 04:国保, 05:広域 労災, 06:自賠責, 07:新様式, 08:従来様式, 09:第三者行為 公害
  EOS
  exit(1)
end

require_relative "../common"

argv0 = ARGV.shift
if argv0.downcase == "all"
  receipt_mode = "All"
  perform_month = ARGV.shift
  patients = []
else
  receipt_mode = ""
  perform_month = ""
  patients = argv0.split(",").map { |s|
    s.split(":")
  }
end
in_out = ARGV.shift.upcase
print_mode = ARGV.shift.downcase == "check" ? "Check" : "Normal"
submission_mode = ARGV.shift

service = @orca_api.new_receipt_service

args = {
  "Perform_Date" => "", # 実施年月日/10
  "Perform_Month" => perform_month, # 診療年月/7/処理区分がAll のとき必須
  "InOut" => in_out, # 入外区分/1/必須　　I：入院　O：入院外
  "Receipt_Mode" => receipt_mode, # 処理区分/10/All：一括作成　All以外：個別作成
  "Print_Mode" => print_mode, # 印刷モード/6/Check：点検用　Check以外：提出用　　※２
  "Submission_Mode" => submission_mode, # 提出先/2/必須　※３
  "Patient_Information" => [], # 個別対象患者一覧/100/個別作成のとき必須
}

args["Patient_Information"] = patients.map { |patient_id, patient_perform_month|
  {
    "Patient_ID" => patient_id, # 患者番号/20
    "Patient_Perfrm_Month" => patient_perfrm_month, # 診療年月/7
  }
}

# ※２　個別作成でCheck(点検用)のとき、点検用は平成２０年４月診療分から対応のため診療年月が平成２０年３月以前の場合は提出用として作成します。
# ※３　医保 01:全件 02:社保 03:国保 04:広域 労災 05 自賠責 06:新様式 07:従来様式 08:第三者行為 公害 09

# 作成指示
result = service.create(args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end

# 作成確認
args["Orca_Uid"] = result["Orca_Uid"]

result = service.created(args)
while !result.ok? && result.api_result == "E70"
  print_result(result)
  sleep(1)
  result = service.created(args)
end

if result.ok?
  print_result(result)
else
  error(result)
  exit
end

# 印刷指示
args["Print_Mode"] = "All" # 印刷モード/5/All：全件印刷 All以外：個別印刷

result = service.print(args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end

data_id_information = result["Data_Id_Information"]

# 印刷結果確認
result = service.printed(args)
while !result.ok? && result.api_result == "E70"
  print_result(result)
  sleep(1)
  result = service.printed(args)
end

if result.ok?
  print_result(result)
else
  error(result)
end

puts "＊＊＊＊＊ＩＤ一覧＊＊＊＊＊"
pp data_id_information
