if ![4, 5].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  create.rb <type> <patient_id> <invoice_number> <outside_class> [enable_push_notification]
    type: 'shohosen' or 'okusuri_techo'
    outside_class: 't' = outside, other = inside
    enable_push_notification: any = enable push notification
  EOS
  exit(1)
end

require_relative "../common"

type = ARGV.shift
patient_id = ARGV.shift
invoice_number = ARGV.shift
outside_class = (ARGV.shift == "t" ? true : false)
push_notification = !!ARGV.shift

service = @orca_api.new_print_service

result = service.create(type, patient_id, invoice_number, outside_class, push_notification)
if result.ok?
  print_result(result)
else
  error(result)
end
