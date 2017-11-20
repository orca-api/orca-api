if ![1].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  get.rb <data_id>
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_form_data_service

data_id = ARGV.shift

result = service.get(data_id)
if result.ok?
  print_result(result)
else
  error(result)
end
