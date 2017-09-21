# -*- coding: utf-8 -*-
require_relative "../common"

patient_service = @orca_api.new_patient_service

result = patient_service.destroy(ARGV.shift)
if result.ok?
  puts "＊＊＊＊＊#{result.message}＊＊＊＊＊"
  puts ""
  puts "対象患者"
  pp result.patient_information
else
  error(result)
end
