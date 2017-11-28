require "uri"
require "net/http"
require "json"
require "securerandom"

require_relative "result"
require_relative "form_result"
require_relative "binary_result"

require_relative "error"

module OrcaApi
  # 日医レセAPIを呼び出すため低レベルインタフェースを提供するクラス
  #
  # リクエスト毎に日レセAPIの接続先を切り替えられるように、接続・認証情報をこのクラスのオブジェクトに保持する。
  # また、スレッド毎に別のオブジェクトを生成することを想定しており、
  # 同じオブジェクトに複数のスレッドからアクセスすることはできない。
  #
  # 基本的には、低レベルインタフェースを使わなくても電子カルテのアプリケーションが組めるように、
  # 高レベルインターフェースを提供する。
  #
  # `OrcaApi::OrcaApi#debug_output=` に IO オブジェクトを設定すると、日レセAPIとのやりとりを IO に出力できる。
  #
  # ```ruby
  # orca_api.debug_output = $stdout
  # ```
  #
  # 接続・認証に関するサンプルプログラムは `/example/common.rb` を参照。
  # また、低レベルインタフェースに関するサンプルプログラムは `/example/orca_api/call.rb` を参照。
  class OrcaApi
    attr_accessor :host # ホスト名
    attr_accessor :port # ポート番号
    attr_accessor :user # ユーザー名
    attr_accessor :password # パスワード
    attr_accessor :use_ssl # SSL通信をするかどうか
    attr_accessor :ca_file # CA証明書のパス
    attr_accessor :ca_path # CA証明書を格納しているディレクトリのパス
    attr_accessor :verify_mode # サーバ証明書の検証モード
    attr_accessor :cert # クライアント証明書
    attr_accessor :key # 暗号鍵
    attr_writer :karte_uid # カルテUID
    attr_accessor :debug_output # デバッグに使う `IO` オブジェクト

    def self.underscore(name)
      name.
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        downcase
    end

    # @param uri [String]
    #   接続先のURI。
    #   スキーマはhttpとhttpsに対応。ただし、https以外を指定された場合は強制的にhttpでの通信とみなす。
    #   認証情報は https://username:password@hostname として指定できる。
    #   ポートを指定しない場合は http だと 80 番、https だと 443 番ポートを指定したものとみなす。
    # @param [Hash] options
    #   * :user (String)
    #     ユーザー名。ただし、uriのユーザー名が優先される。
    #   * :password (String)
    #     パスワード。ただし、uriのパスワードが優先される。
    #   * :use_ssl (Boolean)
    #     SSL通信を行うかどうか。
    #     ただし、uriのスキーマがhttpsだった場合、この値に関わらずtrueを指定したものとして扱われる。
    #   * :ssl (Hash)
    #     SSL通信に関するオプション
    #     * :ca_file (String)
    #       CA証明書のパス
    #     * :ca_path (String)
    #       CA証明書を格納しているディレクトリのパス
    #     * :verify (Boolean) [true]
    #       サーバ証明書を検証するかどうか
    #     * :verify_mode (Integer)
    #       サーバ証明書の検証モード。
    #       `OpenSSL::SSL` モジュールに定義されている `VERIFY_`　から始まる定数を指定することを想定。
    #     * :p12 (OpenSSL::PKCS12)
    #       PKCS#12 (秘密鍵、証明書、関連するCA証明書を1つのファイルに保存する形式)のクライアント証明書
    #     * :cert (OpenSSL::X509::Certificate)
    #       クライアント証明書
    #     * :key (OpenSSL::PKey::PKey)
    #       暗号鍵。
    #       鍵の種類に応じて `OpenSSL::PKey::RSA` 等の適切なクラスのインスタンスを指定する。
    def initialize(uri, options = {})
      uri = URI.parse(uri)
      @host = uri.host
      @port = uri.port
      @user = uri.user || options[:user]
      @password = uri.password || options[:password]
      @use_ssl = uri.scheme == 'https' || options[:use_ssl]
      if @use_ssl
        extract_ssl_options(options.fetch(:ssl))
      end
    end

    def karte_uid
      @karte_uid ||= SecureRandom.uuid
    end

    # 任意の日レセAPIを呼び出す
    #
    # 引数paramsやbodyの内容のチェックは行わない。
    #
    # 結果はRubyのオブジェクト(HashやArray等)が返る。処理結果を番号で格納したApi_Resultでさえ、
    # 値のフォーマットや意味が様々であるため、結果の内容のチェックも行わない。
    #
    # @param [String] path
    #   エンドポイント
    # @param [Hash{String,Symbol=>String}] params
    #   リクエストパラメータ
    # @param [#to_json,nil] body
    #   リクエストボディ。
    #   nilとfalse以外が指定された場合、 `#to_json` を呼び出してJSON形式に変換してからリクエストボディに指定する。
    # @param [:get,:post] http_method (:post)
    #   HTTPメソッド
    # @return [Object]
    #   ブロックが指定された場合、HTTPレスポンスをブロックパラメータに指定して、ブロックを呼び出した結果を返す。
    #   そうでない場合、HTTPレスポンスのbodyをJSON形式として扱い、Rubyのオブジェクトに解析した結果を返す。
    def call(path, params: {}, body: nil, http_method: :post)
      req = make_request(http_method, path, params, body)
      new_http.start { |http|
        res = http.request(req)
        case res
        when Net::HTTPSuccess
          res.body
        else
          raise HttpError, res
        end
      }
    end

    service_class_names = %w(
      PatientService
      InsuranceService
      DepartmentService
      PhysicianService
      MedicalPracticeService
      AcceptanceService
      DiseaseService
      FormDataService
      IncomeService
      PrintService
      ImageService
    )
    service_class_names.each do |name|
      s = underscore(name)

      require_relative s

      service_class = ::OrcaApi.const_get(name)
      define_method("new_#{s}") do
        service_class.new(self)
      end
    end

    private

    def extract_ssl_options(ssl)
      @ca_file = ssl[:ca_file]
      @ca_path = ssl[:ca_path]

      @verify_mode = ssl.fetch(:verify_mode) do
        if ssl.fetch(:verify, true)
          OpenSSL::SSL::VERIFY_PEER
        else
          OpenSSL::SSL::VERIFY_NONE
        end
      end

      if (p12 = ssl[:p12])
        @cert = p12.certificate
        @key = p12.key
      else
        @cert = ssl[:cert]
        @key = ssl[:key]
      end
    end

    def new_http
      http = Net::HTTP.new(@host, @port)

      if @use_ssl
        http.use_ssl = true
        if @cert
          http.cert = @cert
        end
        if @key
          http.key = @key
        end
        if @ca_file
          http.ca_file = @ca_file
        end
        if @ca_path
          http.ca_path = @ca_path
        end
        if @verify_mode
          http.verify_mode = @verify_mode
        end
      end

      if @debug_output
        http.set_debug_output(@debug_output)
      end

      http
    end

    def make_request(http_method, path, params, body)
      case http_method
      when :get
        request_class = Net::HTTP::Get
      when :post
        request_class = Net::HTTP::Post
      end

      query = URI.encode_www_form(params.merge(format: "json"))

      req = request_class.new("#{path}?#{query}")

      req.basic_auth(@user, @password)

      if body
        req.body = body.to_json
      end

      req
    end
  end
end
