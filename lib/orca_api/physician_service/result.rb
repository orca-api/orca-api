# coding: utf-8

require_relative "../result"

module OrcaApi
  class PhysicianService < Service
    # ドクターコードを扱うサービスの処理の結果を表現するクラス
    class Result < ::OrcaApi::Result
      json_attr_reader :Physician_Information
    end
  end
end
