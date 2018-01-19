if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  update.rb <patient_id> <json>
    json: path to json file (ex: example/rehabilitation_comment_service/update.json)
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_rehabilitation_comment_service

patient_id = ARGV.shift
args = JSON.parse(File.read(ARGV.shift))

result = service.update(patient_id, args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
