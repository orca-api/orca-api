require "optparse"
require_relative "../common"

args = {}
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
Usage: #{opts.program_name} <submission_mode> [options]
         submission_mode: 提出先
                          医保　02:社保 03:国保 04:広域
                          労災　05
  EOS
  opts.on("--perform-date 実施年月日 YYYY-mm", String) { |v| args["Perform_Date"] = v }
  opts.on("--perform-month 診療年月 YYYY-mm", String) { |v| args["Perform_Month"] = v }
  opts.on("--ac-date 請求年月日 YYYY-mm-dd", String) { |v| args["Ac_Date"] = v }
  opts.on("--receipt-mode 処理区分", String) { |v| args["Receipt_Mode"] = v }
  opts.on("--in-out 入外区分 i:入院 o:入院外 oi or io:入院、入院外", String) { |v| args["InOut"] = v.upcase }
  opts.on("--check-mode レセ電データチェック Yes:チェックする Yes以外:チェックしない", String) { |v| args["Check_Mode"] = v }
  opts.on("--insurance-provider-number 直接請求する保険者番号", String) { |v| args["InsuranceProvider_Number"] = v }
  opts.on("--start-month 期間指定(開始年月)  YYYY-mm", String) { |v| args["Start_Month"] = v }
  opts.on("--end-month 期間指定(終了年月)  YYYY-mm", String) { |v| args["End_Month"] = v }
end

parser.parse!(ARGV)
args["Submission_Mode"] = ARGV.shift

service = @orca_api.new_receipt_data_service
result = service.create(args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end

data_id_information = result["Data_Id_Information"]

args["Orca_Uid"] = result.orca_uid
while (result = service.created(args)).doing?
  print_result(result)
  sleep(1)
end

if result.ok?
  print_result(result)
else
  error(result)
end

puts "＊＊＊＊＊ＩＤ一覧＊＊＊＊＊"
pp data_id_information
