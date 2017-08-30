# coding: utf-8

module OrcaApi
  class PatientService < Service
    # 患者情報の取得
    module Get
      # 患者情報の取得の結果を表現するクラス
      class Result < ::OrcaApi::PatientService::Result
        %w(
          health_public_insurance
        ).each do |association_name|
          result_name = "#{association_name}_result"
          attr_accessor result_name

          define_method(association_name) do
            instance_variable_get("@#{result_name}").send(association_name)
          end
        end
      end

      def get(id, associations: [])
        api_path = "/orca12/patientmodv31"
        req_name = "patientmodreq"

        body = {
          req_name => {
            "Request_Number" => "01",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => id.to_s,
            "Patient_Mode" => "Modify",
            "Orca_Uid" => "",
          }
        }
        res = Result.new(orca_api.call(api_path, body: body))

        unlock(api_path,
               req_name => {
                 "Request_Number" => "99",
                 "Karte_Uid" => res.karte_uid,
                 "Patient_ID" => res.patient_information["Patient_ID"],
                 "Orca_Uid" => res.orca_uid,
               })

        associations.each do |association|
          res.send("#{association}_result=", send("get_#{association}", id))
        end

        res
      end
    end
  end
end
