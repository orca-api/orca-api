# coding: utf-8

require_relative "../result"

module OrcaApi
  class AcceptanceService < Service
    class Result < ::OrcaApi::Result
    end

    class ListResult < Result
      def acceptance_date
        body["Acceptance_Date"]
      end

      def list
        Array(body["Acceptlst_Information"])
      end
    end
  end
end
