if ![5].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} <patient_id> <pi_id> <number> <start_date> <json>
    pi_id: public insurance id
    number: public insurance money number
    start_date: public insurance money start date
    json: path to json file (ex: example/patient_service/pi_etc_money/update__modify.json)
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
pi_id = ARGV.shift
number = ARGV.shift
start_date = ARGV.shift
args = JSON.parse(File.read(ARGV.shift))

result = patient_service.update_pi_money_etc(patient_id, pi_id, number, start_date, args)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
