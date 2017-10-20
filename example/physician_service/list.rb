# -*- coding: utf-8 -*-

if ![0].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  list.rb
  EOS
  exit(1)
end

require_relative "../common"

service = @orca_api.new_physician_service

result = service.list
if result.ok?
  print_result(result, "Physician_Information")
else
  error(result)
end
