# -*- coding: utf-8 -*-
require_relative "../../common"

patient_service = @orca_api.new_patient_service
patient_id = ARGV.shift

# 一括更新なので空配列で更新した場合は、全禁忌薬剤情報が削除される
result = patient_service.update_contraindication(patient_id, {
                                                   "Contra_Mode" => "Modify",
                                                   "Patient_Contra_Info" => []
                                                 })
error(result) && exit(1) unless result.ok?
puts 'result["Patient_Contra_Information"]'
pp result["Patient_Contra_Information"]
result = patient_service.get_contraindication(patient_id)
error(result) && exit(1) unless result.ok?
pp result["Patient_Contra_Information"]

result = patient_service.update_contraindication(patient_id, {
                                                   "Contra_Mode" => "Modify",
                                                   "Patient_Contra_Info" => [
                                                     {"Medication_Code" => "620000064"},
                                                     {"Medication_Code" => "611170749", "Contra_StartDate" => "2017-12-01"},
                                                     {"Medication_Code" => "610453103", "Contra_StartDate" => "2017-12-01", "Medication_StartDate" => "2017-08-01"},
                                                     {"Medication_Code" => "610463147", "Medication_StartDate" => "2017-08-01"}
                                                   ]
                                                 })
error(result) && exit(1) unless result.ok?
pp result["Patient_Contra_Information"]
result = patient_service.get_contraindication(patient_id)
error(result) && exit(1) unless result.ok?
pp result["Patient_Contra_Information"]

result = patient_service.update_contraindication(patient_id, {
                                                   "Contra_Mode" => "Modify",
                                                   "Patient_Contra_Info" => [
                                                     {"Medication_Code" => "610463147", "Medication_StartDate" => "2017-08-02"}
                                                   ]
                                                 })
error(result) && exit(1) unless result.ok?
pp result["Patient_Contra_Information"]
result = patient_service.get_contraindication(patient_id)
error(result) && exit(1) unless result.ok?
pp result["Patient_Contra_Information"]

result = patient_service.update_contraindication(patient_id, {
                                                   "Contra_Mode" => "Modify",
                                                   "Patient_Contra_Info" => [
                                                     {"Medication_Code" => "620000064"},
                                                     {"Medication_Code" => "620000064"},
                                                   ]
                                                 })
pp result["Patient_Contra_Information"]
