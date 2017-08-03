# coding: utf-8

require_relative "create_medical_practice/result"

module OrcaApi
  class PatientService < Service
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    # rubocop:disable Metrics/ModuleLength, Metrics/PerceivedComplexity

    # 診療行為の登録
    module CreateMedicalPractice
      def create_medical_practice(id, diagnosis)
        locked = false

        body = {
          "medicalv3req1" => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => id.to_s,
            "Perform_Date" => diagnosis["Perform_Date"],
            "Perform_Time" => diagnosis["Perform_Time"],
            "Orca_Uid" => "",
            "Diagnosis_Information" => diagnosis["Diagnosis_Information"],
          },
        }
        res = Result.new(orca_api.call("/api21/medicalmodv31", body: body))
        if !res.ok?
          return res
        end

        locked = true

        if !diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"]
          return EmptyMedicalInfoError.new(res.raw)
        end

        body = {
          "medicalv3req2" => {
            "Request_Number" => res.response_number,
            "Karte_Uid" => res.karte_uid,
            "Patient_ID" => res.patient_information["Patient_ID"],
            "Perform_Date" => res.body["Perform_Date"],
            "Perform_Time" => res.body["Perform_Time"],
            "Orca_Uid" => res.orca_uid,
            "Diagnosis_Information" => {
              "Department_Code" => res.body["Department_Code"],
              "Physician_Code" => res.body["Physician_Code"],
              "HealthInsurance_Information" => res.patient_information["HealthInsurance_Information"],
              "Outside_Class" => diagnosis["Diagnosis_Information"]["Outside_Class"],
              "Medical_OffTime" => res.body["Medical_OffTime"],
              "Medical_Information" => {
                "Medical_Info" => diagnosis["Diagnosis_Information"]["Medical_Information"]["Medical_Info"],
              }
            },
          },
        }
        res = Result.new(orca_api.call("/api21/medicalmodv32", body: body))
        if !res.ok?
          return res
        end

        body = {
          "medicalv3req2" => {
            "Request_Number" => res.response_number,
            "Karte_Uid" => res.karte_uid,
            "Patient_ID" => res.patient_information["Patient_ID"],
            "Perform_Date" => res.body["Perform_Date"],
            "Perform_Time" => res.body["Perform_Time"],
            "Orca_Uid" => res.orca_uid,
          },
        }
        res = Result.new(orca_api.call("/api21/medicalmodv32", body: body))
        while !res.ok?
          if res.body["Medical_Select_Flag"] == "True"
            if diagnosis["Medical_Select_Information"]
              answer = diagnosis["Medical_Select_Information"].find { |i|
                i["Medical_Select"] == res.body["Medical_Select_Information"]["Medical_Select"] && i["Select_Answer"]
              }
            end
            if answer
              body = {
                "medicalv3req2" => {
                  "Request_Number" => res.response_number,
                  "Karte_Uid" => res.karte_uid,
                  "Patient_ID" => res.patient_information["Patient_ID"],
                  "Perform_Date" => res.body["Perform_Date"],
                  "Perform_Time" => res.body["Perform_Time"],
                  "Orca_Uid" => res.orca_uid,
                  "Select_Answer" => answer["Select_Answer"],
                },
              }
              res = Result.new(orca_api.call("/api21/medicalmodv32", body: body))
            else
              return UnselectedError.new(res.raw)
            end
          else
            return res
          end
        end

        can_delete = res.medical_information["Medical_Info"].any? { |i| i["Medical_Delete_Number"] }
        if can_delete && !diagnosis["Delete_Number_Info"]
          return EmptyDeleteNumberInfoError.new(res.raw)
        end

        body = {
          "medicalv3req3" => {
            "Request_Number" => res.response_number,
            "Karte_Uid" => res.karte_uid,
            "Base_Date" => diagnosis["Base_Date"],
            "Patient_ID" => res.patient_information["Patient_ID"],
            "Perform_Date" => res.body["Perform_Date"],
            "Orca_Uid" => res.orca_uid,
            "Medical_Mode" => (can_delete && diagnosis["Delete_Number_Info"] ? "1" : nil),
            "Delete_Number_Info" => diagnosis["Delete_Number_Info"],
            "Ic_Code" => diagnosis["Ic_Code"],
            "Ic_Money" => diagnosis["Ic_Money"],
            "Ad_Money1" => diagnosis["Ad_Money1"],
            "Ad_Money2" => diagnosis["Ad_Money2"],
          },
        }
        res = Result.new(orca_api.call("/api21/medicalmodv33", body: body))
        if !res.ok?
          return res
        end

        if ["Ic_Code", "Ic_Money", "Ad_Money1"].any? { |n| !diagnosis[n] }
          return EmptyIcError.new(res.raw)
        end

        body = {
          "medicalv3req3" => {
            "Request_Number" => res.response_number,
            "Karte_Uid" => res.karte_uid,
            "Base_Date" => diagnosis["Base_Date"],
            "Patient_ID" => res.patient_information["Patient_ID"],
            "Perform_Date" => res.body["Perform_Date"],
            "Orca_Uid" => res.orca_uid,
            "Ic_Code" => diagnosis["Ic_Code"],
            "Ic_Money" => diagnosis["Ic_Money"],
            "Ad_Money1" => diagnosis["Ad_Money1"],
            "Ad_Money2" => diagnosis["Ad_Money2"],
          },
        }
        res = Result.new(orca_api.call("/api21/medicalmodv33", body: body))
        if !res.ok?
          return res
        end
        locked = false
        return res
      ensure
        if locked
          body = {
            "medicalv3req1" => {
              "Request_Number" => "99",
              "Karte_Uid" => orca_api.karte_uid,
              "Patient_ID" => id.to_s,
              "Perform_Date" => res.body["Perform_Date"],
              "Orca_Uid" => res.orca_uid,
            },
          }
          orca_api.call("/api21/medicalmodv31", body: body)
        end
      end
    end

    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    # rubocop:enable Metrics/ModuleLength, Metrics/PerceivedComplexity
  end
end
