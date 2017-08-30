# coding: utf-8

module OrcaApi
  class MedicalPracticeService < Service #:nodoc:
    # 診療行為の登録の結果を表現するクラス
    class Result < ::OrcaApi::Result
      def ok?
        api_result == "W00" || super()
      end
    end

    # 選択項目が未指定であることを表現するクラス
    class UnselectedError < ::OrcaApi::PatientService::Result
      def ok?
        false
      end

      def message
        '選択項目が未指定です。'
      end
    end

    # 削除可能な剤の削除指示が未指定であることを表現するクラス
    class EmptyDeleteNumberInfoError < ::OrcaApi::PatientService::Result
      def ok?
        false
      end

      def message
        '削除可能な剤の削除指示が未指定です。'
      end
    end
  end
end
