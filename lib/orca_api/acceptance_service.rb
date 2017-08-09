# coding: utf-8

require_relative "service"
require_relative "acceptance_service/result"

module OrcaApi
  class AcceptanceService < Service
    # https://www.orca.med.or.jp/receipt/tec/api/acceptancelst.html
    def list(klass: "03", base_date: nil, department_code: nil, physician_code: nil, medical_information: nil)
      api_path = "/api01rv2/acceptlstv2"
      req_name = "acceptlstreq"

      params = {
        class: klass
      }

      request = {}
      request["Acceptance_Date"] = base_date if base_date
      request["Department_Code"] = department_code if department_code
      request["Physician_Code"] = physician_code if physician_code
      request["Medical_Information"] = medical_information if medical_information

      body = {
        req_name => request
      }

      ListResult.new(orca_api.call(api_path, params: params, body: body))
    end

    # https://www.orca.med.or.jp/receipt/tec/api/acceptmod.html
    def create(acceptance)
      api_path = "/orca11/acceptmodv2"
      req_name = "acceptreq"

      params = {
        class: "01"
      }

      body = {
        req_name => acceptance
      }

      Result.new(orca_api.call(api_path, params: params, body: body))
    end

    # https://www.orca.med.or.jp/receipt/tec/api/acceptmod.html
    def destroy(acceptance_id, patient_id)
      api_path = "/orca11/acceptmodv2"
      req_name = "acceptreq"

      params = {
        class: "02"
      }

      body = {
        req_name => {
          "Acceptance_Id" => acceptance_id,
          "Patient_ID" => patient_id
        }
      }

      Result.new(orca_api.call(api_path, params: params, body: body))
    end

    def new_builder
      AcceptanceBuilder.new
    end

    class AcceptanceBuilder
      def initialize
        @data = {}
        @health_insurance = {}
      end

      def accept_at(accept_at = Time.now)
        @data['Acceptance_Date'] = accept_at.strftime("%F")
        @data['Acceptance_Time'] = accept_at.strftime("%T")
        self
      end

      %w[Patient_ID Department_Code Physician_Code Medical_Information].each do |name|
        define_method name.downcase do |value|
          @data[name] = value
          self
        end
      end

      def insurance_combination_number(value)
        @health_insurance['Insurance_Combination_Number'] = value
        self
      end

      def to_h
        if @health_insurance.empty?
          @data
        else
          @data.merge('HealthInsurance_Information' => @health_insurance)
        end
      end
    end
  end
end
