# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service

result = patient_service.get_health_public_insurance(ARGV.shift)
if result.ok?
  pp result.patient_information
  pp result.health_public_insurance
else
  error(result)
end
