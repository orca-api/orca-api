require "abbrev"
require "optparse"
require "time"
require_relative "../common"

actions = %w[create get update destroy]

args = {}
json_path = nil
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: #{opts.program_name} #{actions.join("|")} [options]
  EOS
  opts.on("--patient-id 患者ID", String) { |v| args["Patient_ID"] = v }
  opts.on("--perform-date 受付日。YYYY-mm-dd形式", String) { |v| args["Perform_Date"] = v }
  opts.on("--invoice-number (get,update,destroy) 伝票番号", String) { |v| args["Invoice_Number"] = v }
  opts.on("--department-code (get,destroy) 診療科", String) { |v| args["Department_Code"] = v }
  opts.on("--insurance-combination-number (get,destroy) 保険組合せ番号", String) { |v| args["Insurance_Combination_Number"] = v }
  opts.on("--sequential-number (get,destroy) 連番", String) { |v| args["Sequential_Number"] = v }
  opts.on("--json (create,update) JSONファイルのパス", String) { |v| json_path = v }
end

OPS = Abbrev.abbrev(actions)
ops = ARGV.shift.to_s
ops = OPS.find { |(a, e)| ops == a }
unless ops
  STDERR.puts(parser.help)
  exit 1
end
action = ops.last
parser.parse(ARGV)

service = @orca_api.new_medical_practice_service

result = case action
         when "get", "destroy"
           service.send(action, args)
         when "create", "update"
           service.send(action, JSON.parse(File.read(json_path)).merge(args))
         end
if result.ok?
  print_result(result)
else
  error(result)
end
