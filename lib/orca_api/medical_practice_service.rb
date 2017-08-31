# coding: utf-8

require_relative "service"

module OrcaApi
  # 診療行為を扱うサービスを表現したクラス
  class MedicalPracticeService < Service
    # 診療行為の登録・削除・訂正の結果を表現するクラス
    class Result < ::OrcaApi::Result
      def ok?
        api_result == "W00" || super()
      end
    end

    # 選択項目が未指定であることを表現するクラス
    class UnselectedError < Result
      def ok?
        false
      end

      def message
        '選択項目が未指定です。'
      end
    end

    # 削除可能な剤の削除指示が未指定であることを表現するクラス
    class EmptyDeleteNumberInfoError < Result
      def ok?
        false
      end

      def message
        '削除可能な剤の削除指示が未指定です。'
      end
    end

    # 診察料情報の取得
    def get_examination_fee(params)
      res = call_api21_medicalmodv31_01(params)
      if !res.locked?
        unlock_api21_medicalmodv31(res)
      end
      res
    end

    # 診療情報及び請求情報の取得
    def calc_medical_practice_fee(params)
      if params["Invoice_Number"]
        if (di = params["Diagnosis_Information"])
          department_code = di["Department_Code"]
          if (hii = di["HealthInsurance_Information"])
            insurance_combination_number = hii["Insurance_Combination_Number"]
          end
        end
        res = call_api21_medicalmodv34_01(
          params.merge(
            "Department_Code" => department_code,
            "Insurance_Combination_Number" => insurance_combination_number
          ), "Modify"
        )
      else
        res = call_api21_medicalmodv31_01(params)
      end
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end

      calc_medical_practice_fee_without_unlock(params, res)
    ensure
      unlock_api21_medicalmodv31(locked_result)
    end

    # 診療行為の登録
    def create(params)
      if params["Invoice_Number"]
        if (di = params["Diagnosis_Information"])
          department_code = di["Department_Code"]
          if (hii = di["HealthInsurance_Information"])
            insurance_combination_number = hii["Insurance_Combination_Number"]
          end
        end
        res = call_api21_medicalmodv34_01(
          params.merge(
            "Department_Code" => department_code,
            "Insurance_Combination_Number" => insurance_combination_number
          ), "Modify"
        )
      else
        res = call_api21_medicalmodv31_01(params)
      end
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end

      res = calc_medical_practice_fee_without_unlock(params, res)
      if !res.ok?
        return res
      end

      res = call_api21_medicalmodv33_05(params, res)
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock_api21_medicalmodv31(locked_result)
    end

    # 診療行為の取得
    def get(params)
      res = call_api21_medicalmodv34_01(params, "Modify")
      if !res.locked?
        locked_result = res
      end
      res
    ensure
      unlock_api21_medicalmodv34(locked_result)
    end

    # 診療行為の削除
    def destroy(params)
      res = call_api21_medicalmodv34_01(params, "Delete")
      if !res.locked?
        locked_result = res
      end
      if res.api_result != "S30"
        return res
      end

      res = call_api21_medicalmodv34_02(res)
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock_api21_medicalmodv34(locked_result)
    end

    # 薬剤併用禁忌チェック
    def check_contraindication(params)
      body = {
        "contraindication_checkreq" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
        }.merge(params),
      }
      ::OrcaApi::Result.new(orca_api.call("/api01rv2/contraindicationcheckv2", body: body))
    end

    private

    def call_api21_medicalmodv31_01(params)
      body = {
        "medicalv3req1" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => params["Patient_ID"],
          "Perform_Date" => params["Perform_Date"],
          "Perform_Time" => params["Perform_Time"],
          "Orca_Uid" => "",
          "Diagnosis_Information" => params["Diagnosis_Information"],
        },
      }
      Result.new(orca_api.call("/api21/medicalmodv31", body: body))
    end

    def call_api21_medicalmodv32_02(params, previous_result)
      res = previous_result
      res_body = res.body
      req = {
        "Request_Number" => res.response_number,
        "Karte_Uid" => res.karte_uid,
        "Patient_ID" => res.patient_information["Patient_ID"],
        "Perform_Date" => res_body["Perform_Date"],
        "Orca_Uid" => res.orca_uid,
        "Diagnosis_Information" => {
          "Department_Code" => res_body["Department_Code"],
          "Physician_Code" => res_body["Physician_Code"],
          "Outside_Class" => params["Diagnosis_Information"]["Outside_Class"],
          "Medical_Information" => {
            "Medical_Info" => params["Diagnosis_Information"]["Medical_Information"]["Medical_Info"],
          }
        }
      }
      if res_body["Invoice_Number"]
        req["Perform_Time"] = params["Perform_Time"]
        req["Invoice_Number"] = res_body["Invoice_Number"]
        req["Patient_Mode"] = "Modify"
        req["Diagnosis_Information"]["HealthInsurance_Information"] = res.health_insurance_information
        req["Diagnosis_Information"]["Medical_OffTime"] = params["Diagnosis_Information"]["Medical_Information"]["OffTime"]
      else
        req["Perform_Time"] = res_body["Perform_Time"]
        req["Diagnosis_Information"]["HealthInsurance_Information"] =
          res.patient_information["HealthInsurance_Information"]
        req["Diagnosis_Information"]["Medical_OffTime"] = res_body["Medical_OffTime"]
      end
      Result.new(orca_api.call("/api21/medicalmodv32", body: { "medicalv3req2" => req }))
    end

    def call_api21_medicalmodv32_03(previous_result, answer = nil)
      res = previous_result
      req = {
        "Request_Number" => res.response_number,
        "Karte_Uid" => res.karte_uid,
        "Patient_ID" => res.patient_information["Patient_ID"],
        "Perform_Date" => res.body["Perform_Date"],
        "Perform_Time" => res.body["Perform_Time"],
        "Orca_Uid" => res.orca_uid,
      }
      if res.body["Invoice_Number"]
        req["Invoice_Number"] = res.invoice_number
        req["Patient_Mode"] = "Modify"
      end
      if answer
        req["Select_Answer"] = answer["Select_Answer"]
      end
      Result.new(orca_api.call("/api21/medicalmodv32", body: { "medicalv3req2" => req }))
    end

    def call_api21_medicalmodv33_04(params, previous_result)
      res = previous_result

      can_delete = res.medical_information["Medical_Info"].any? { |i| i["Medical_Delete_Number"] }
      if can_delete && !params["Delete_Number_Info"]
        return EmptyDeleteNumberInfoError.new(res.raw)
      end

      req = {
        "Request_Number" => res.response_number,
        "Karte_Uid" => res.karte_uid,
        "Base_Date" => params["Base_Date"],
        "Patient_ID" => res.patient_information["Patient_ID"],
        "Perform_Date" => res.body["Perform_Date"],
        "Orca_Uid" => res.orca_uid,
        "Medical_Mode" => (can_delete && params["Delete_Number_Info"] ? "1" : nil),
        "Delete_Number_Info" => params["Delete_Number_Info"],
        "Ic_Code" => params["Ic_Code"],
        "Ic_Request_Code" => params["Ic_Request_Code"],
        "Ic_All_Code" => params["Ic_All_Code"],
        "Cd_Information" => params["Cd_Information"],
        "Print_Information" => params["Print_Information"],
      }
      if params["Invoice_Number"]
        req["Patient_Mode"] = "Modify"
      end
      Result.new(orca_api.call("/api21/medicalmodv33", body: { "medicalv3req3" => req }))
    end

    def call_api21_medicalmodv33_05(params, previous_result)
      res = previous_result
      req = {
        "Request_Number" => res.response_number,
        "Karte_Uid" => res.karte_uid,
        "Base_Date" => params["Base_Date"],
        "Patient_ID" => res.patient_information["Patient_ID"],
        "Perform_Date" => res.body["Perform_Date"],
        "Orca_Uid" => res.orca_uid,
        "Ic_Code" => params["Ic_Code"],
        "Ic_Request_Code" => params["Ic_Request_Code"],
        "Ic_All_Code" => params["Ic_All_Code"],
        "Cd_Information" => params["Cd_Information"],
        "Print_Information" => params["Print_Information"],
      }
      if params["Invoice_Number"]
        req["Patient_Mode"] = "Modify"
      end
      Result.new(orca_api.call("/api21/medicalmodv33", body: { "medicalv3req3" => req }))
    end

    def calc_medical_practice_fee_without_unlock(params, get_examination_fee_result)
      res = call_api21_medicalmodv32_02(params, get_examination_fee_result)
      if !res.ok?
        return res
      end

      res = call_api21_medicalmodv32_03(res)
      while !res.ok?
        if res.body["Medical_Select_Flag"] == "True"
          if params["Medical_Select_Information"]
            answer = params["Medical_Select_Information"].find { |i|
              i["Medical_Select"] == res.body["Medical_Select_Information"]["Medical_Select"] && i["Select_Answer"]
            }
          end
          if answer
            res = call_api21_medicalmodv32_03(res, answer)
          else
            return UnselectedError.new(res.raw)
          end
        else
          return res
        end
      end

      call_api21_medicalmodv33_04(params, res)
    end

    def unlock_api21_medicalmodv31(locked_result)
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

    def call_api21_medicalmodv34_01(params, patient_mode)
      body = {
        "medicalv3req4" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => "",
          "Patient_ID" => params["Patient_ID"],
          "Perform_Date" => params["Perform_Date"],
          "Patient_Mode" => patient_mode,
          "Invoice_Number" => params["Invoice_Number"],
          "Department_Code" => params["Department_Code"],
          "Insurance_Combination_Number" => params["Insurance_Combination_Number"],
          "Sequential_Number" => params["Sequential_Number"],
        },
      }
      Result.new(orca_api.call("/api21/medicalmodv34", body: body))
    end

    def call_api21_medicalmodv34_02(previous_result)
      res = previous_result
      body = {
        "medicalv3req4" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => res.orca_uid,
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Perform_Date" => res.perform_date,
          "Patient_Mode" => "Delete",
          "Invoice_Number" => res.invoice_number,
          "Department_Code" => res.department_code,
          "Insurance_Combination_Number" => res.health_insurance_information["Insurance_Combination_Number"],
          "Sequential_Number" => res.sequential_number,
          "Select_Answer" => "Ok",
        },
      }
      Result.new(orca_api.call("/api21/medicalmodv34", body: body))
    end

    def unlock_api21_medicalmodv34(locked_result)
      if locked_result
        body = {
          "medicalv3req4" => {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => locked_result.patient_information["Patient_ID"],
            "Perform_Date" => locked_result.perform_date,
            "Orca_Uid" => locked_result.orca_uid,
          },
        }
        orca_api.call("/api21/medicalmodv34", body: body)
        # TODO: エラー処理
      end
    end
  end
end
