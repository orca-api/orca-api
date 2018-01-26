if ![4].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  #{File.basename(__FILE__)} <patient_id> <pi_id> <number> <start_date>
    pi_id: public insurance id
    number: public insurance money number
    start_date: public insurance money start date
  EOS
  exit(1)
end

require_relative "../../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
pi_id = ARGV.shift
number = ARGV.shift
start_date = ARGV.shift

result = patient_service.get_pi_etc_money(patient_id, pi_id, number, start_date)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
