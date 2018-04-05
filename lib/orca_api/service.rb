module OrcaApi
  # 各種情報を扱うサービスを表現したクラス
  # 高レベルインターフェースは、　OrcaApi::Client のインスタンスメソッドで、オブジェクトを作成することを前提。
  # 接続・認証情報は、各オブジェクトのプロパティ(orca_api)に保持。
  #
  # @example
  #   some_object = orca_api.new_some_class
  #   some_object.orca_api == orca_api
  #   #=> true
  #
  #   result = some_object.method1
  #   # method1では接続先、認証情報を指定しなくていい。
  #   # また、日レセのバージョンを極力意識しなくてもいいようにする。
  #
  # 高レベルインターフェースはロックしない。あくまで1トランザクション完結として扱う。
  # ロックしたいケースが仮にあるなら、低レベルインタフェースを使用する。
  # 具体的には、患者情報の更新中に診療行為をさせないといった排他制御はorca-apiを利用するアプリケーションで行う。
  # ```
  # アプリケーションによるロック
  #  > 患者情報の取得 (参照時にORCA側で患者情報がロックされるが、変更なしで患者情報を更新してロックを解除する)
  #  > 患者情報の入力
  #  > 患者情報の更新 (ORCA側のロックは利用しない = Continue_Mode=False)
  # アプリケーションによるロックの解除
  # ```
  #
  class Service
    attr_reader :orca_api

    # OrcaApi::Client#reuse_session でラップするためのマクロメソッド
    #
    # あるメソッド内で複数回 OrcaApi::Client#call を呼び出す時、#call ごとにその都度HTTPセッションが作成される。
    #
    # http keep-alive が有効な場合、作成したHTTPセッションを使いまわすことで、パフォーマンスを向上させることができる。
    #
    # @param method_names [<Symbol, String>]
    #   ラップするメソッド名
    # @return [Module]
    #   プリペンドされたModule
    #
    # @example
    #   class SomeService < Service
    #     def get(id)
    #       response = orca_api.call("/api/foo")
    #       return response unless response.ok?
    #       response = orca_api.call("/api/bar")
    #     end
    #     reuse_session :get
    #   end
    #
    # @see OrcaApi::Client#reuse_session
    # @see OrcaApi::Client#reusing_session?
    def self.reuse_session(*method_names)
      wrapper = Module.new do
        method_names.each do |method_name|
          define_method(method_name) do |*args, &blk|
            orca_api.reuse_session do
              super(*args, &blk)
            end
          end
        end
      end
      prepend wrapper
      wrapper
    end

    def initialize(orca_api)
      @orca_api = orca_api
    end
  end
end
