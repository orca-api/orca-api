# coding: utf-8

module OrcaApi
  class PatientService
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
    end
  end
end
