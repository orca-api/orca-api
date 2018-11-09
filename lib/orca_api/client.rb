require "uri"
require "net/http"
require "json"
require "securerandom"

require_relative "result"
require_relative "form_result"
require_relative "binary_result"

require_relative "error"

module OrcaApi #:nodoc:
  # 日医レセAPIを呼び出すため低レベルインタフェースを提供するクラス
  #
  # リクエスト毎に日レセAPIの接続先を切り替えられるように、接続・認証情報をこのクラスのオブジェクトに保持する。
  # また、スレッド毎に別のオブジェクトを生成することを想定しており、
  # 同じオブジェクトに複数のスレッドからアクセスすることはできない。
  #
  # 基本的には、低レベルインタフェースを使わなくても電子カルテのアプリケーションが組めるように、
  # OrcaApi::Service クラスを継承した高レベルインターフェースを提供する。
  #
  # `OrcaApi::Client#debug_output=` に IO オブジェクトを設定すると、日レセAPIとのやりとりを IO に出力できる。
  #
  # ```ruby
  # orca_api.debug_output = $stdout
  # ```
  #
  # 接続・認証に関するサンプルプログラムは `/example/common.rb` を参照。
  # また、低レベルインタフェースに関するサンプルプログラムは `/example/orca_api/call.rb` を参照。
  class Client
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
    attr_reader :timeout

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
    #   * :timeout (Hash)
    #     タイムアウトに関するオプション
    #     * :ssl (Integer)
    #       SSL/TLSのタイムアウト秒数
    #     * :open (Integer)
    #       接続時のタイムアウト秒数
    #     * :read (Integer)
    #       読み込み時のタイムアウト秒数
    #     * :continue (Integer)
    #       「100 Continue」レスポンスを待つタイムアウト秒数
    #     * :keep_alive (Integer)
    #       コネクションの再利用(keep-alive)を許可する秒数
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
      @reuse_http = 0
      self.timeout = options[:timeout]
    end

    # カルテUIDの取得
    # OrcaApi::Client#karte_uid= で明示的に設定しない場合は、OrcaApi::Client のインスタンス毎にユニークな値を自動生成する
    #
    # @return [String] カルテUID
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
    # @param [String] format ("json")
    #   リクエストボディとレスポンスボディの形式。"json"を指定するとJSON形式でやりとりする。
    # @param [IO] output_io (nil)
    #   レスポンスボディを格納するIO。
    #   大容量データを取得するときのように、サイズが大きくてメモリに展開することが難しい場合に指定する。
    # @return [IO,String]
    #   output_ioが指定された場合、output_ioを返す。
    #   そうでない場合、HTTPレスポンスのbodyをそのまま文字列として返す。
    def call(path, params: {}, body: nil, http_method: :post, format: "json", output_io: nil)
      do_call make_request(http_method, path, params, body, format), output_io
    end

    # @!group 高レベルインターフェース

    # @!method new_patient_service
    # @return [PatientService] PatientServiceインスタンス

    # @!method new_insurance_service
    # @return [InsuranceService] InsuranceServiceインスタンス

    # @!method new_department_service
    # @return [DepartmentService] DepartmentServiceインスタンス

    # @!method new_physician_service
    # @return [PhysicianService] PhysicianServiceインスタンス

    # @!method new_medical_practice_service
    # @return [MedicalPracticeService] MedicalPracticeServiceインスタンス

    # @!method new_acceptance_service
    # @return [AcceptanceService] AcceptanceServiceインスタンス

    # @!method new_disease_service
    # @return [DiseaseService] DiseaseServiceインスタンス

    # @!method new_form_data_service
    # @return [FormDataService] FormDataServiceインスタンス

    # @!method new_income_service
    # @return [IncomeService] IncomeServiceインスタンス

    # @!method new_print_service
    # @return [PrintService] PrintServiceインスタンス

    # @!method new_image_service
    # @return [ImageService] ImageServiceインスタンス

    # @!method new_receipt_service
    # @return [ReceiptService] ReceiptServiceインスタンス

    # @!method new_blob_service
    # @return [BlobService] BlobServiceインスタンス

    # @!method new_lock_service
    # @return [LockService] LockServiceインスタンス

    # @!method new_rehabilitation_comment_service
    # @return [RehabilitationCommentService] RehabilitationCommentServiceインスタンス

    # @!method new_user_service
    # @return [UserService] UserServiceインスタンス

    # @!method new_receipt_data_service
    # @return [ReceiptDataService] ReceiptDataServiceインスタンス

    # @!method new_find_service
    # @return [FindService] FindServiceインスタンス

    # @!method new_statistics_form_service
    # @return [StatisticsFormServie] StatisticsFormServiceインスタンス

    # @!endgroup

    service_class_names = %w(
      AcceptanceService
      BlobService
      DepartmentService
      DiseaseService
      FindService
      FormDataService
      ImageService
      IncomeService
      InsuranceService
      LockService
      MedicalPracticeService
      PatientService
      PhysicianService
      PrintService
      ReceiptDataService
      ReceiptService
      RehabilitationCommentService
      StatisticsFormService
      SubjectiveService
      UserService
    )
    service_class_names.each do |name|
      s = OrcaApi.underscore(name)

      require_relative s

      service_class = ::OrcaApi.const_get(name)
      define_method("new_#{s}") do
        service_class.new(self)
      end
    end

    def reuse_session
      start_reuse_session
      yield
    ensure
      finish_reuse_session
    end

    def reusing_session?
      @reuse_http.positive?
    end

    def timeout=(timeout)
      @timeout = extract_timeout_options timeout
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

    ACCEPT_TIMEOUT_OPTIONS = %i[ssl open read continue keep_alive].freeze
    private_constant :ACCEPT_TIMEOUT_OPTIONS

    def extract_timeout_options(timeout)
      return {} unless timeout

      timeout.select { |key, _| ACCEPT_TIMEOUT_OPTIONS.include? key }
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

      @timeout.each do |key, value|
        http.__send__ "#{key}_timeout=", value
      end

      http
    end

    def make_request(http_method, path, params, body, format)
      case http_method
      when :get
        request_class = Net::HTTP::Get
      when :post
        request_class = Net::HTTP::Post
      end

      if format && !format.empty?
        params = params.merge(format: format.to_s)
      end

      req = if params.empty?
              request_class.new(path)
            else
              query = URI.encode_www_form(params)
              request_class.new("#{path}?#{query}")
            end

      req.basic_auth(@user, @password)

      if body
        req.body = body.to_json
      end

      req
    end

    def start_reuse_session
      @reuse_http += 1
    end

    def finish_reuse_session
      @reuse_http -= 1
      return if reusing_session?

      @reuse_http = 0
      @http.finish if @http&.started?
      @http = nil
    end

    def do_call(request, output_io)
      if reusing_session?
        @http ||= new_http
        @http.start unless @http.started?
        do_request @http, request, output_io
      else
        new_http.start do |http|
          do_request http, request, output_io
        end
      end
    end

    def do_request(http, request, output_io)
      http.request(request) do |response|
        case response
        when Net::HTTPSuccess
          if output_io
            response.read_body do |chunk|
              output_io.write(chunk)
            end
            output_io.rewind
            return output_io
          else
            return response.body
          end
        else
          raise HttpError, response
        end
      end
    end
  end

  # 0.2.xまでの移行措置のため
  OrcaApi = Client
  deprecate_constant :OrcaApi
end
