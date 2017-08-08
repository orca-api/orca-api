# coding: utf-8

module OrcaApi
  class PatientService < Service
    module CreateMedicalPractice
      # 診療行為の登録の結果を表現するクラス
      class Result < ::OrcaApi::PatientService::Result
        json_attr_reader :Invoice_Number, :Medical_Information, :Cd_Information

        def ok?
          api_result == "W00" || super()
        end
      end

      # 診療行為が未指定であることを表現するクラス
      class EmptyMedicalInfoError < ::OrcaApi::PatientService::Result
        json_attr_reader :Medical_Information

        def ok?
          false
        end

        def message
          '診療行為情報が未指定です。'
        end
      end

      # 選択項目が未指定であることを表現するクラス
      class UnselectedError < ::OrcaApi::PatientService::Result
        json_attr_reader :Medical_Information, :Medical_Select_Information

        def ok?
          false
        end

        def message
          '選択項目が未指定です。'
        end
      end

      # 削除可能な剤の削除指示が未指定であることを表現するクラス
      class EmptyDeleteNumberInfoError < ::OrcaApi::PatientService::Result
        json_attr_reader :Medical_Information

        def ok?
          false
        end

        def message
          '削除可能な剤の削除指示が未指定です。'
        end
      end

      # 入金情報が未指定であることを表現するクラス
      class EmptyIcError < ::OrcaApi::PatientService::Result
        json_attr_reader :Medical_Information, :Cd_Information

        def ok?
          false
        end

        def message
          '入金情報が未指定です。'
        end
      end
    end
  end
end
