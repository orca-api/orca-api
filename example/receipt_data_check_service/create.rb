require "optparse"
require_relative "../common"

args = {}
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
Usage: #{opts.program_name} <submission_mode> <patient_id> <patient_perform_month> <paient_in_out> [options]
         submission_mode: 提出先
                          医保　02:社保 03:国保 04:広域
                          労災　05
         patient_id: 対象患者番号
         patient_perform_month: 診療年月 YYYY-mm
         patient_in_out: 入外区分
                         I:入院 O:入院外 IO、OI:入院、入院外
  EOS
  opts.on("--perform-date 実施年月日 YYYY-mm", String) { |v| args["Perform_Date"] = v }
  opts.on("--perform-month 診療年月 YYYY-mm", String) { |v| args["Perform_Month"] = v }
  opts.on("--ac-date 請求年月日 YYYY-mm-dd", String) { |v| args["Ac_Date"] = v }
  opts.on("--create-mode 作成モード", String) { |v| args["Create_Mode"] = v }
  opts.on("--check-mode レセ電データチェック Yes:チェックする Yes以外:チェックしない", String) { |v| args["Check_Mode"] = v }
  opts.on("--insurance-provider-number 直接請求する保険者番号", String) { |v| args["InsuranceProvider_Number"] = v }
  opts.on("--start-month 期間指定(開始年月)  YYYY-mm", String) { |v| args["Start_Month"] = v }
  opts.on("--end-month 期間指定(終了年月)  YYYY-mm", String) { |v| args["End_Month"] = v }
end

parser.parse!(ARGV)
args["Submission_Mode"] = ARGV.shift
args["Patient_Information"] = [
  {
    "Patient_ID" => ARGV.shift,
    "Patient_Perform_Month" => ARGV.shift,
    "Patient_InOut" => ARGV.shift,
  }
]

service = @orca_api.new_receipt_data_check_service
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
__END__
# 必要に応じてORCA_API_URIを設定した上で下記のように実行する

$ bundle exec ruby example/receipt_data_check_service/create.rb 02 00713 2019-03 IO --perform-month 2019-03 --start 2018-10 --end 9999-99

...

＊＊＊＊＊ＩＤ一覧＊＊＊＊＊
[{"Data_Id"=>"846dd527-e7cb-4789-8a2c-2a25efdad6b3",
  "Print_Id"=>"1605c6e3-425f-48be-80b3-1929f250377f"}]

$ curl http://your-orca-host/blobapi/846dd527-e7cb-4789-8a2c-2a25efdad6b3 -o test.uke
