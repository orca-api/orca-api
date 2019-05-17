require "abbrev"
require "optparse"
require "time"
require_relative "./common"

actions = %w[create update destroy out_create]
# class=01（登録）->create
# class=02（削除）->destroy
# class=03（変更）->update
# class=04 (外来追加)->out_create

args = {}
json_path = nil
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: #{opts.program_name} #{actions.join("|")} [options]
  EOS
  opts.on("--perform-date 診療日。YYYY-mm-dd形式", String) { |v| args["Perform_Date"] = v }
  opts.on("--in-out 入外区分（I: 入院、それ以外: 入院外）", String) { |v| args["InOut"] = v }
  opts.on("--department-code 診療科コード", String) { |v| args["Department_Code"] = v }
  opts.on("--patient-id 患者ID", String) { |v| args["Patient_ID"] = v }
end

parser.parse(ARGV)
service = @orca_api.new_interruption_service
result = service.list(args)
if result.ok?
  print_result(result)
else
  error(result)
end
