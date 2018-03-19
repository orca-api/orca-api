require "abbrev"
require "optparse"
require "time"
require_relative "../common"

actions = %w[create list update destroy]

args = {}
parser = OptionParser.new do |opts|
  opts.banner = <<-EOS
  Usage: #{opts.program_name} #{actions.join("|")} [options]
  EOS
  opts.on("--klass (list) 種別 01:受付中、02:会計済、03:全受付", String) { |v| args[:klass] = v }
  opts.on("--base-date (list) 受付日 YYYY-mm-dd", String) { |v| args[:base_date] = v }
  opts.on("--department-code (list,create,update) 診療科コード", String) { |v| args[:department_code] = v }
  opts.on("--physician-code (list,create,update) ドクターコード", String) { |v| args[:physician_code] = v }
  opts.on("--medical-information (list,create,update) 診療内容区分", String) { |v| args[:medical_information] = v }
  opts.on("--accept-at (create,update) 受付日時 YYYY-mm-ddTHH:MM:SS", String) { |v| args[:accept_at] = Time.parse(v) }
  opts.on("--patient-id (create,update) 患者番号", String) { |v| args[:patient_id] = v }
  opts.on("--acceptance-id (update) 受付ID", String) { |v| args[:acceptance_id] = v }
  opts.on("--insurance-combination-number (crete,update) 保険組合せ番号", String) { |v| args[:insurance_combination_number] = v }
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

service = @orca_api.new_acceptance_service

result = case action
         when "list"
           names = %i(
             klass
             base_date
             department_code
             physician_code
             medical_information
           )
           service.list(args.select { |k, _| names.include?(k) })
         when "create", "update"
           builder = service.new_builder
           %i(
             accept_at
             patient_id
             department_code
             physician_code
             medical_information
             insurance_combination_number
           ).each do |name|
             if args.key?(name)
               builder.send(name, args[name])
             end
           end
           if action == "create"
             service.create(builder.to_h)
           else
             service.update(args[:acceptance_id], builder.to_h)
           end
         when "destroy"
           service.destroy(args[:acceptance_id], args[:patient_id])
         end

if result.ok?
  print_result(result)
else
  error(result)
  exit
end
