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
  opts.on("--in-out 入外区分（I: 入院、それ以外: 入院外）", String) { |v| args["InOut"] = v }
  opts.on("--patient-id 患者ID", String) { |v| args["Patient_ID"] = v }
  opts.on("--perform-date 診療日。YYYY-mm-dd形式", String) { |v| args["Perform_Date"] = v }
  opts.on("--perform-time 診療時間。HH:MM:SS形式", String) { |v| args["Perform_Time"] = v }
  opts.on("--json JSONファイルのパス", String) { |v| json_path = v }
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
args = JSON.parse(File.read(json_path)).merge(args)
service = @orca_api.new_interruption_service
result = case action
         when 'create'
           service.create(args)
         when 'destroy'
           service.destroy(args)
         when 'update'
           service.update(args)
         when 'out_create'
           service.out_create(args)
         end
if result.ok?
  print_result(result)
else
  error(result)
end
