module OrcaApi
  # 各種情報を扱うサービスを表現したクラス
  class Service
    attr_reader :orca_api

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
