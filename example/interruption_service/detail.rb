require "abbrev"
require "optparse"
require "time"
require_relative "../common"

args = {}
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: ruby #{__FILE__} [options]
  EOS
  opts.on("--perform-date 診療日。YYYY-mm-dd形式", String) { |v| args["Perform_Date"] = v }
  opts.on("--in-out 入外区分（I: 入院、それ以外: 入院外）", String) { |v| args["InOut"] = v }
  opts.on("--department-code 診療科コード", String) { |v| args["Department_Code"] = v }
  opts.on("--patient-id 患者ID", String) { |v| args["Patient_ID"] = v }
  opts.on("--medical-uid Medical_Uid", String) { |v| args["Medical_Uid"] = v }
  opts.on("--insurance-combination-number 保険組合せ番号", String) { |v| args["Insurance_Combination_Number"] = v }
end

parser.parse(ARGV)
service = @orca_api.new_interruption_service
result = service.detail(args)
if result.ok?
  print_result(result)
else
  error(result)
end
__END__

# 実行例

```

$ ORCA_API_URI=http://xxx bundle exec ruby example/interruption_service/detail.rb --perform-date 2019-05-01 --in-out O --department-code 01 --patient-id 00501 --medical-uid

```
