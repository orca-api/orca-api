if ![1].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  list.rb <patient_id>
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_rehabilitation_comment_service

patient_id = ARGV.shift

result = service.list(patient_id)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
