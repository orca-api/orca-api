# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service

result = patient_service.get_accident_insurance(ARGV.shift)
if result.ok?
  pp result.patient_information
  pp result["Accident_Insurance_Information"]
else
  error(result)
end
