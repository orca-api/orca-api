# -*- coding: utf-8 -*-

if ![1, 2].include?(ARGV.length)
  $stderr.puts(<<-EOS)
Usage:
  destroy.rb <patient_id> ["force"]
  EOS
  exit(1)
end

require_relative "../common"

patient_service = @orca_api.new_patient_service

patient_id = ARGV.shift
force = (ARGV.shift || "").downcase == "force" ? { force: true } : {}

result = patient_service.destroy(patient_id, force)
if result.ok?
  puts "＊＊＊＊＊#{result.message}＊＊＊＊＊"
  puts ""
  puts "対象患者"
  pp result.patient_information
else
  error(result)
end
