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
    PATIENT_GET_REQ_02 = {
      "Request_Number" => PLACE_HOLDER,
      "Karte_Uid" => PLACE_HOLDER,
      "Patient_ID" => PLACE_HOLDER,
      "Patient_Mode" => "Modify",
      "Orca_Uid" => PLACE_HOLDER,
      "Continue_Mode" => "",
      "Patient_Information" => PLACE_HOLDER,
      "Modify_Option" => {
        "Former_Name_Mode" => "",
      }.freeze
    }.freeze
    PATIENT_GET_RES_NAME = "patientmodres".freeze

    attr_reader :orca_api

    def initialize(orca_api)
      @orca_api = orca_api
    end

    def get(id)
      # 患者情報の取得
      karte_uid = "123456789012345678901234567890123456" # TODO: Karte_Uidはorca_apiに持たせる
      body = {
        PATIENT_GET_REQ_NAME => PATIENT_GET_REQ_01.merge(
          "Karte_Uid" => karte_uid,
          "Patient_ID" => id.to_s
        )
      }
      res = orca_api.call(PATIENT_GET_PATH, body: body)
      patientmodres = res[PATIENT_GET_RES_NAME]
      if patientmodres["Request_Number"].to_i <= patientmodres["Response_Number"].to_i
        # TODO: エラー処理
      end

      # ロック解除
      patient_id = patientmodres["Patient_Information"].delete("Patient_ID")
      body = {
        PATIENT_GET_REQ_NAME => PATIENT_GET_REQ_02.merge(
          "Request_Number" => patientmodres["Response_Number"],
          "Karte_Uid" => patientmodres["Karte_Uid"],
          "Patient_ID" => patient_id,
          "Orca_Uid" => patientmodres["Orca_Uid"],
          "Patient_Information" => patientmodres["Patient_Information"]
        )
      }
      res = orca_api.call(PATIENT_GET_PATH, body: body)
      patientmodres = res[PATIENT_GET_RES_NAME]
      if patientmodres["Response_Number"].to_i != 0
        # TODO: エラー処理
      end

      Patient.new(patientmodres["Patient_Information"])
    end
  end
end
