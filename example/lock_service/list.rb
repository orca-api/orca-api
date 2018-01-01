require_relative "../common"

service = @orca_api.new_lock_service

result = service.list
if result.ok?
  print_result(result)
else
  error(result)
  exit
end
