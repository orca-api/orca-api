if ![4].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  get.rb <patient_id> <medication_code> <perform_date> <insurance_combination_number>
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_rehabilitation_comment_service

patient_id = ARGV.shift
medication_code = ARGV.shift
perform_date = ARGV.shift
insurance_combination_number = ARGV.shift

result = service.get(patient_id, medication_code, perform_date, insurance_combination_number)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
