# coding: utf-8

require_relative "service"

module OrcaApi
  # 患者情報を扱うサービスを表現したクラス
  #
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v031.pdf
  # @see http://cms-edit.orca.med.or.jp/receipt/tec/api/haori_patientmod.data/api12v031_err.pdf
  class PatientService < Service
    # 患者情報の登録の結果を表現するクラス
    class CreateResult < ::OrcaApi::Result
      def duplicated_patient_candidates
        body["Patient2_Information"] || []
      end
    end

    # 患者情報の取得の結果を表現するクラス
    class GetResult < ::OrcaApi::Result
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

    # 患者情報の登録
    def create(patient_information, allow_duplication: false)
      res = CreateResult.new(call_orca12_patientmodv31_01("*", patient_information, "New"))
      if !res.ok? && !res.duplicated_patient_candidates.empty? && allow_duplication
        res = CreateResult.new(call_orca12_patientmodv31_02(patient_information, "New", res))
      end
      res
    end

    # 患者情報の取得
    def get(id, associations: [])
      res = GetResult.new(call_orca12_patientmodv31_01(id, nil, "Modify"))
      if !res.locked?
        unlock_orca12_patientmodv31(res)
      end

      associations.each do |association|
        res.send("#{association}_result=", send("get_#{association}", id))
      end

      res
    end

    # 患者情報の更新
    def update(id, patient_information)
      res = Result.new(call_orca12_patientmodv31_01(id, nil, "Modify"))
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end
      patient_information = deep_merge_for_request_body(res.patient_information, patient_information)
      res = Result.new(call_orca12_patientmodv31_02(patient_information, "Modify", res))
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock_orca12_patientmodv31(locked_result)
    end

    # 患者情報の削除
    def destroy(id, force: false)
      res = Result.new(call_orca12_patientmodv31_01(id, nil, "Delete"))
      if !res.locked?
        locked_result = res
      end
      if !res.ok?
        return res
      end
      res = Result.new(call_orca12_patientmodv31_02(res.patient_information, "Delete", res))
      if res.api_result != "S20"
        return res
      end
      res = Result.new(call_orca12_patientmodv31_02(res.patient_information, "Delete", res))
      if res.ok?
        # 該当患者に受診履歴、病名等の入力がない場合
        locked_result = nil
        return res
      end
      if res.api_result != "S20" || !force
        return res
      end
      # 該当患者に受診履歴、病名等の入力がある場合
      res = Result.new(call_orca12_patientmodv31_02(res.patient_information, "Delete", res))
      if res.ok?
        locked_result = nil
      end
      res
    ensure
      unlock_orca12_patientmodv31(locked_result)
    end

    %w(
      HealthPublicInsurance
      AccidentInsurance
      Income
      Pension
      Maiden
      SpecialNotes
      Personally
    ).each do |class_name|
      method_suffix = OrcaApi.underscore(class_name)
      require_relative "patient_service/#{method_suffix}"
      klass = const_get(class_name)

      define_method("get_#{method_suffix}") do |*args|
        klass.new(orca_api).get(*args)
      end

      define_method("update_#{method_suffix}") do |*args|
        klass.new(orca_api).update(*args)
      end
    end

    private

    def call_orca12_patientmodv31_01(id, patient_information, patient_mode)
      body = {
        "patientmodreq" => {
          "Request_Number" => "01",
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => id.to_s,
          "Patient_Mode" => patient_mode,
          "Orca_Uid" => "",
          "Select_Answer" => "",
          "Patient_Information" => patient_information,
        }
      }
      orca_api.call("/orca12/patientmodv31", body: body)
    end

    def call_orca12_patientmodv31_02(patient, patient_mode, previous_result)
      res = previous_result
      body = {
        "patientmodreq" => {
          "Request_Number" => res.response_number,
          "Karte_Uid" => orca_api.karte_uid,
          "Patient_ID" => res.patient_information["Patient_ID"],
          "Patient_Mode" => patient_mode,
          "Orca_Uid" => res.orca_uid,
          "Select_Answer" => "Ok",
          "Patient_Information" => patient,
        }
      }
      orca_api.call("/orca12/patientmodv31", body: body)
    end

    def unlock_orca12_patientmodv31(locked_result)
      if locked_result && locked_result.respond_to?(:orca_uid)
        body = {
          "patientmodreq" => {
            "Request_Number" => "99",
            "Karte_Uid" => orca_api.karte_uid,
            "Patient_ID" => locked_result.patient_information["Patient_ID"],
            "Orca_Uid" => locked_result.orca_uid,
          }
        }
        orca_api.call("/orca12/patientmodv31", body: body)
      end
    end

    def deep_merge_for_request_body(dest, src)
      res = dest&.clone || {}
      case src
      when Hash
        src.each do |k, v|
          res[k] = case v
                   when Hash
                     deep_merge_for_request_body(dest[k], v)
                   when nil
                     ""
                   else
                     v
                   end
        end
      end
      res
    end
  end
end
