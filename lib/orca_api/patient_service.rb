# coding: utf-8

require_relative "patient"

module OrcaApi
  # 患者情報を扱うサービスを表現したクラス
  class PatientService
    PLACE_HOLDER = "%place_holder%".freeze
    private_constant :PLACE_HOLDER

    PATIENT_GET_PATH = "/orca12/patientmodv31".freeze
    PATIENT_GET_REQ_NAME = "patientmodreq".freeze
    PATIENT_GET_REQ_01 = {
      "Request_Number" => "01",
      "Karte_Uid" => PLACE_HOLDER,
      "Patient_ID" => PLACE_HOLDER,
      "Patient_Mode" => "Modify",
      "Orca_Uid" => "",
    }.freeze
    PATIENT_GET_REQ_99 = {
      "Request_Number" => "99",
      "Karte_Uid" => PLACE_HOLDER,
      "Patient_ID" => PLACE_HOLDER,
      "Orca_Uid" => PLACE_HOLDER,
    }.freeze
    PATIENT_GET_RES_NAME = "patientmodres".freeze

    attr_reader :orca_api

    def initialize(orca_api)
      @orca_api = orca_api
    end

    def get(id)
      # 患者情報の取得
      body = {
        PATIENT_GET_REQ_NAME => PATIENT_GET_REQ_01.merge(
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => id.to_s
        )
      }
      res0 = orca_api.call(PATIENT_GET_PATH, body: body)
      res = res0[PATIENT_GET_RES_NAME]
      if res["Request_Number"].to_i <= res["Response_Number"].to_i
        # TODO: エラー処理
      end

      patient = Patient.new(res["Patient_Information"])

      # ロック解除
      body = {
        PATIENT_GET_REQ_NAME => PATIENT_GET_REQ_99.merge(
          "Karte_Uid" => res["Karte_Uid"],
          "Patient_ID" => res["Patient_Information"]["Patient_ID"],
          "Orca_Uid" => res["Orca_Uid"]
        )
      }
      res0 = orca_api.call(PATIENT_GET_PATH, body: body)
      res = res0[PATIENT_GET_RES_NAME]
      if res["Response_Number"] != "00"
        # TODO: エラー処理
      end

      patient
    end
  end
end
