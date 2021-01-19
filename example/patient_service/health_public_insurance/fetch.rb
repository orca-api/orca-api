# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service
id = ARGV.shift
base_date = ARGV.shift

result = patient_service.fetch_health_public_insurance(id, base_date)
if result.ok?
  pp result.patient_information
  pp result.health_public_insurance
else
  error(result)
end
