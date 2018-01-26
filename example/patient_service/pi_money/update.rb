if ![3].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} <patient_id> <pi_id> <json>
    pi_id: public insurance id
    json: path to json file (ex: example/patient_service/pi_money/update__modify.json)
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
pi_id = ARGV.shift
args = JSON.parse(File.read(ARGV.shift))

result = patient_service.update_pi_money(patient_id, pi_id, args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
