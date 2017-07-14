# coding: utf-8

module OrcaApi
  class PatientService
    module Create
      # 患者情報の登録のリクエストボディを表現するクラス
      class RequestBody
        INCLUDE_FILTER_SETTINGS = {
          PatientInformation => %w(
            WholeName WholeName_inKana BirthDate Sex HouseHolder_WholeName Relationship Occupation NickName CellularNumber
            FaxNumber EmailAddress Contraindication1 Contraindication2 Allergy1 Allergy2 Infection1 Infection2 Comment1
            Comment2 TestPatient_Flag Death_Flag Reduction_Reason Discount Condition1 Condition2 Condition3
            Home_Address_Information WorkPlace_Information Contact_Information Home2_Information
          ),
          PatientInformation::HomeAddressInformation => %w(
            Address_ZipCode WholeAddress1 WholeAddress2 PhoneNumber1 PhoneNumber2
          ),
          PatientInformation::WorkPlaceInformation => %w(
            WholeName Address_ZipCode WholeAddress1 WholeAddress2 PhoneNumber
          ),
          PatientInformation::ContactInformation => %w(
            WholeName Relationship Address_ZipCode WholeAddress1 WholeAddress2 PhoneNumber1 PhoneNumber2
          ),
          PatientInformation::Home2Information => %w(
            WholeName Address_ZipCode WholeAddress1 WholeAddress2 PhoneNumber
          ),
        }.freeze
        private_constant :INCLUDE_FILTER_SETTINGS

        attr_accessor :karte_uid
        attr_accessor :patient_information
        attr_accessor :request_number
        attr_accessor :orca_uid
        attr_accessor :select_answer

        def initialize(karte_uid:, patient_information:, request_number: "01", orca_uid: "", select_answer: "")
          @karte_uid = karte_uid
          @patient_information =
            patient_information.is_a?(PatientInformation) ? patient_information : PatientInformation.new(patient_information)
          @request_number = request_number
          @orca_uid = orca_uid
          @select_answer = select_answer
        end

        def to_json
          patient_information_attrs = patient_information.attributes(name_type: :json, omit: true) { |api_struct, json_name, _|
            INCLUDE_FILTER_SETTINGS.key?(api_struct.class) && INCLUDE_FILTER_SETTINGS[api_struct.class].include?(json_name)
          }
          {
            "patientmodreq" => {
              "Request_Number" => request_number,
              "Karte_Uid" => karte_uid,
              "Patient_ID" => "*",
              "Patient_Mode" => "New",
              "Orca_Uid" => orca_uid,
              "Select_Answer" => select_answer,
              "Patient_Information" => patient_information_attrs,
            }
          }.to_json
        end
      end
    end
  end
end
