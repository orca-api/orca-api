# coding: utf-8

require_relative "../result"

module OrcaApi
  class DepartmentService < Service
    # 診療科コードを扱うサービスの処理の結果を表現するクラス
    class Result < ::OrcaApi::Result
      json_attr_reader :Department_Information
    end
  end
end
