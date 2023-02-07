module OrcaApi
  class PatientService < Service
    class AllHealthInsurances < Service
      def get(id)
        api_path = "/api01rv2/patientlst6v2"

        body = {
          "patientlst6req" => {
            "Reqest_Number" => "01",
            "Patient_ID" => id.to_s
          }
        }

        Result.new(orca_api.call(api_path, body: body))
      end
    end
  end
end
