module OrcaApi
  class OrcaApi
    # BASIC認証を表現するクラス
    class BasicAuthentication
      attr_accessor :account
      attr_accessor :password

      def initialize(account, password)
        @account = account
        @password = password
      end

      def apply(_http, request)
        request.basic_auth(account, password)
      end
    end
  end
end
