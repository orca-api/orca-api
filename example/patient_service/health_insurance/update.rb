if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} <patient_id> <json>
    json: path to json file (ex: example/patient_service/health_insurance/update__modify.json)
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
args = JSON.parse(File.read(ARGV.shift))

result = patient_service.update_health_insurance(patient_id, args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
