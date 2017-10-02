# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service

result = patient_service.get_pension(ARGV.shift)
if result.ok?
  pp result.patient_information
  pp result["Pension_Information"]
else
  error(result)
end
