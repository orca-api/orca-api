# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service

result = patient_service.get_personally(ARGV.shift)
if result.ok?
  pp result.patient_information
  pp result["Personally_Information"]
else
  error(result)
end
