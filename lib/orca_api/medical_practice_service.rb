# coding: utf-8

require_relative "service"
require_relative "medical_practice_service/result"

module OrcaApi
  # 診療行為を扱うサービスを表現したクラス
  class MedicalPracticeService < Service
    # 診察料情報の取得
    def get_examination_fee(diagnosis)
      res = call_request_number_01(diagnosis)
      if res.ok?
        unlock(res)
      end
      res
    end

    # 診療情報及び請求情報の取得
    def calc_medical_practice_fee(diagnosis)
      res = call_request_number_01(diagnosis)
      if res.ok?
        locked_result = res
      else
        return res
      end

      calc_medical_practice_fee_without_unlock(diagnosis, res)
    ensure
      unlock(locked_result)
    end

    # 診療行為の登録
    def create(diagnosis)
      res = call_request_number_01(diagnosis)
      if res.ok?
        locked_result = res
      else
        return res
      end

      res = calc_medical_practice_fee_without_unlock(diagnosis, res)
      if !res.ok?
        return res
      end

      res = call_request_number_05(diagnosis, res)
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock(locked_result)
    end

    # 薬剤併用禁忌チェック
    def check_contraindication(params)
      body = {
        "contraindication_checkreq" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
        }.merge(params),
      }
      CheckContraindicationResult.new(orca_api.call("/api01rv2/contraindicationcheckv2", body: body))
    end

    private

    def call_request_number_01(diagnosis)
      body = {
        "medicalv3req1" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => diagnosis["Patient_ID"],
          "Perform_Date" => diagnosis["Perform_Date"],
          "Perform_Time" => diagnosis["Perform_Time"],
          "Orca_Uid" => "",
          "Diagnosis_Information" => diagnosis["Diagnosis_Information"],
        },
      }
      Result.new(orca_api.call("/api21/medicalmodv31", body: body))
    end

    def call_request_number_02(diagnosis, previous_result)
      res = previous_result
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
      Result.new(orca_api.call("/api21/medicalmodv32", body: body))
    end

    def call_request_number_03(_diagnosis, previous_result, answer = nil)
      res = previous_result
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
      if answer
        body["medicalv3req2"]["Select_Answer"] = answer["Select_Answer"]
      end
      Result.new(orca_api.call("/api21/medicalmodv32", body: body))
    end

    def call_request_number_04(diagnosis, previous_result)
      res = previous_result

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
      Result.new(orca_api.call("/api21/medicalmodv33", body: body))
    end

    def call_request_number_05(diagnosis, previous_result)
      res = previous_result
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
      Result.new(orca_api.call("/api21/medicalmodv33", body: body))
    end

    def calc_medical_practice_fee_without_unlock(diagnosis, get_examination_fee_result)
      res = call_request_number_02(diagnosis, get_examination_fee_result)
      if !res.ok?
        return res
      end

      res = call_request_number_03(diagnosis, res)
      while !res.ok?
        if res.body["Medical_Select_Flag"] == "True"
          if diagnosis["Medical_Select_Information"]
            answer = diagnosis["Medical_Select_Information"].find { |i|
              i["Medical_Select"] == res.body["Medical_Select_Information"]["Medical_Select"] && i["Select_Answer"]
            }
          end
          if answer
            res = call_request_number_03(diagnosis, res, answer)
          else
            return UnselectedError.new(res.raw)
          end
        else
          return res
        end
      end

      call_request_number_04(diagnosis, res)
    end

    def unlock(locked_result)
      if locked_result
        body = {
          "medicalv3req1" => {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Perform_Date" => locked_result.body["Perform_Date"],
            "Orca_Uid" => locked_result.orca_uid,
          },
        }
        orca_api.call("/api21/medicalmodv31", body: body)
        # TODO: エラー処理
      end
    end
  end
end
