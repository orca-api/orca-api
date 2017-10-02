# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service

result = patient_service.get_special_notes(ARGV.shift)
if result.ok?
  pp result.patient_information
  pp result["Special_Notes_Information"]
else
  error(result)
end
