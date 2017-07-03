# coding: utf-8

require_relative "patient_information"
require_relative "health_public_insurance"

module OrcaApi
  # 患者情報を扱うサービスを表現したクラス
  class PatientService
    PLACE_HOLDER = "%place_holder%".freeze
    private_constant :PLACE_HOLDER

    PATIENT_GET_PATH = "/orca12/patientmodv31".freeze
    PATIENT_GET_REQ_NAME = "patientmodreq".freeze
    PATIENT_GET_REQ01 = {
      "Request_Number" => "01",
      "Karte_Uid" => PLACE_HOLDER,
      "Patient_ID" => PLACE_HOLDER,
      "Patient_Mode" => "Modify",
      "Orca_Uid" => "",
    }.freeze
    PATIENT_GET_REQ99 = {
      "Request_Number" => "99",
      "Karte_Uid" => PLACE_HOLDER,
      "Patient_ID" => PLACE_HOLDER,
      "Orca_Uid" => PLACE_HOLDER,
    }.freeze

    HEALTH_PUBLIC_INSURANCE_GET_PATH = "/orca12/patientmodv32".freeze
    HEALTH_PUBLIC_INSURANCE_GET_REQ_NAME = "patientmodreq".freeze
    HEALTH_PUBLIC_INSURANCE_GET_REQ01 = {
      "Request_Number" => "01",
      "Karte_Uid" => PLACE_HOLDER,
      "Orca_Uid" => "",
      "Patient_Information" => {
        "Patient_ID" => PLACE_HOLDER,
      }.freeze
    }.freeze
    HEALTH_PUBLIC_INSURANCE_GET_REQ99 = {
      "Request_Number" => "99",
      "Karte_Uid" => PLACE_HOLDER,
      "Orca_Uid" => PLACE_HOLDER,
      "Patient_Information" => PLACE_HOLDER,
    }.freeze

    attr_reader :orca_api

    def initialize(orca_api)
      @orca_api = orca_api
    end

    # 患者情報の取得
    def get(id)
      req_name = PATIENT_GET_REQ_NAME
      req01 = PATIENT_GET_REQ01
      req99 = PATIENT_GET_REQ99
      api_path = PATIENT_GET_PATH

      body = {
        req_name => req01.merge(
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => id.to_s
        )
      }
      res0 = orca_api.call(api_path, body: body)
      res = res0.first[1]
      if res["Request_Number"].to_i <= res["Response_Number"].to_i
        # TODO: エラー処理
      end

      unlock(api_path,
             req_name => req99.merge(
               "Karte_Uid" => res["Karte_Uid"],
               "Patient_ID" => res["Patient_Information"]["Patient_ID"],
               "Orca_Uid" => res["Orca_Uid"]
             ))

      PatientInformation.new(res["Patient_Information"])
    end

    # 患者保険・公費情報の取得
    def get_health_public_insurance(id)
      req_name = HEALTH_PUBLIC_INSURANCE_GET_REQ_NAME
      req01 = HEALTH_PUBLIC_INSURANCE_GET_REQ01
      req99 = HEALTH_PUBLIC_INSURANCE_GET_REQ99
      api_path = HEALTH_PUBLIC_INSURANCE_GET_PATH

      body = {
        req_name => req01.merge(
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_Information" => req01["Patient_Information"].merge(
            "Patient_ID" => id.to_s
          )
        )
      }
      res0 = orca_api.call(api_path, body: body)
      res = res0.first[1]
      if res["Request_Number"].to_i <= res["Response_Number"].to_i
        # TODO: エラー処理
      end

      unlock(api_path,
             req_name => req99.merge(
               "Karte_Uid" => res["Karte_Uid"],
               "Orca_Uid" => res["Orca_Uid"],
               "Patient_Information" => res["Patient_Information"]
             ))

      HealthPublicInsurance.new(res)
    end

    private

    def unlock(api_path, body)
      res0 = orca_api.call(api_path, body: body)
      res = res0.first[1]
      if res["Response_Number"] != "00"
        # TODO: エラー処理
      end
    end
  end
end
