if ![2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  unlock.rb <karte_uid> <orca_uid>
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_lock_service

karte_uid = ARGV.shift
orca_uid = ARGV.shift

result = service.unlock(karte_uid, orca_uid)
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
