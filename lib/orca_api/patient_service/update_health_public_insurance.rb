# coding: utf-8

require_relative "get_health_public_insurance/result"

module OrcaApi
  class PatientService < Service
    # 患者保険・公費情報の登録・更新・削除
    module UpdateHealthPublicInsurance
      def update_health_public_insurance(id, health_public_insurance)
        locked = false

        res = update_health_public_insurance__call("01", "", { "Patient_ID" => id.to_s })
        if !res.ok?
          return res
        end
        locked = true

        res = update_health_public_insurance__call(res.response_number, res.orca_uid,
                                                   res.health_public_insurance["Patient_Information"],
                                                   health_public_insurance)
        if !res.ok?
          return res
        end

        res = update_health_public_insurance__call(res.response_number, res.orca_uid,
                                                   res.health_public_insurance["Patient_Information"],
                                                   res.health_public_insurance)
        if res.ok?
          locked = false
        end
        return res
      ensure
        if locked
          update_health_public_insurance__call("99", res.orca_uid)
        end
      end

      private

      def update_health_public_insurance__call(request_number, orca_uid, patient = nil, health_public_insurance = nil)
        req = {
          "Request_Number" => request_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Orca_Uid" => orca_uid,
        }
        if patient
          req["Patient_Information"] = patient
        end
        if health_public_insurance
          req["HealthInsurance_Information"] = health_public_insurance["HealthInsurance_Information"]
          req["PublicInsurance_Information"] = health_public_insurance["PublicInsurance_Information"]
        end
        GetHealthPublicInsurance::Result.new(orca_api.call("/orca12/patientmodv32", body: { "patientmodreq" => req }))
      end
    end
  end
end
