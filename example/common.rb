# サンプルプログラムの共通処理
#
# 日レセの認証情報は以下の環境変数で指定することを想定している。
#
#  | 環境変数名            | 説明                                                     |
#  | --------------------- | -------------------------------------------------------- |
#  | ORCA_API_URI          | 接続先のスキーマ、ユーザ名、パスワード、ホスト、ポート   |
#  | ORCA_API_CA_FILE      | CA証明書のパス                                           |
#  | ORCA_API_P12_PATH     | クライアント証明書のパス                                 |
#  | ORCA_API_P12_PASSWORD | クライアント証明書のパスワード                           |
#  | ORCA_API_DEBUG        | 通信のデバッグ出力フラグ                                 |
#  | ORCA_API_KARTE_UID    | カルテUID                                                |
#
# 設定例)
#
#   export ORCA_API_URI="https://ormaster:ormaster@192.168.1.10:8000"
#   export ORCA_API_CA_FILE="/path/to/ca.crt"
#   export ORCA_API_P12_PATH="/path/to/client_cert.p12"
#   export ORCA_API_P12_PASSWORD="client cert password string"
#   export ORCA_API_DEBUG="1"
#   export ORCA_API_KARTE_UID="karte_uid"

require "orca_api"
require "pp"
require "uri"
require "pry-byebug"
require "json"

########################################################################
## 基本設定

uri_str = ENV["ORCA_API_URI"] || "https://ormaster:ormaster@localhost:8000"
uri = URI.parse(uri_str)

options = {}

# https://www.orca.med.or.jp/receipt/use/glserver_ssl_client_verification2.html に従って作成した証明書を想定
if uri.scheme == 'https'
  require "openssl"

  options[:ssl] = {}
  options[:ssl][:ca_file] = ENV["ORCA_API_CA_FILE"]
  if (p12_path = ENV["ORCA_API_P12_PATH"]) && File.exist?(p12_path)
    options[:ssl][:p12] = OpenSSL::PKCS12.new(File.read(p12_path), ENV["ORCA_API_P12_PASSWORD"])
  end
end

########################################################################
## 接続

@orca_api = OrcaApi::OrcaApi.new(uri_str, options)

# デバッグ
if ENV["ORCA_API_DEBUG"]
  @orca_api.debug_output = $stderr
end

# Karte_Uidの設定
# 設定しない場合は、orca_apiのインスタンス毎にユニークな値を自動生成する
@orca_api.karte_uid = ENV["ORCA_API_KARTE_UID"]

########################################################################
## 結果の整形
def print_result(result, *keys)
  if keys.empty?
    hash = result.body
  else
    hash = keys.map { |key|
      [key, result[key]]
    }.to_h
  end
  puts "＊＊＊＊＊正常終了＊＊＊＊＊"
  puts JSON.pretty_generate(hash)
end

########################################################################
## エラー処理
def error(result)
  if result.ok?
    return
  end
  puts "＊＊＊＊＊エラー発生＊＊＊＊＊"
  if result.locked?
    puts "他端末使用中"
  else
    puts result.message
    puts "レスポンスボディ:"
    puts JSON.pretty_generate(result.body)
  end
end

########################################################################
## モンキーパッチ

# 自動テストのための日レセAPIのレスポンスを格納したファイルを
# spec/fixtures/orca_api_responses 以下に生成するためのモンキーパッチ
module CallWithWriteResponse
  def call(path, params: {}, body: nil, http_method: :post, format: "json", output_io: nil)
    raw = super
    parts = []
    parts << path[1..-1].gsub("/", "_")
    begin
      data = JSON.parse(raw.dup)
      if data["Orca_Uid"]
        data["Orca_Uid"] = "c585dc3e-fa42-4f45-b02f-5a4166d0721d"
      elsif (d = data.first[1]) && d["Orca_Uid"]
        d["Orca_Uid"] = "c585dc3e-fa42-4f45-b02f-5a4166d0721d"
      end
      s = JSON.pretty_generate(data)
      res = begin
              OrcaApi::Result.new(raw)
            rescue
              OrcaApi::FormResult.new(raw)
            end
      if res["Request_Number"]
        parts << res["Request_Number"]
      end
      if res["Request_Mode"]
        parts << res["Request_Mode"]
      end
      if !res.ok?
        parts << res.api_result
      end
    rescue
      s = raw
    end
    fixture_path = File.expand_path("../../spec/fixtures/orca_api_responses/#{parts.join('_')}.json", __FILE__)
    File.open(fixture_path, "w") do |f|
      if s.is_a?(IO) || s.is_a?(Tempfile)
        buf = ""
        while s.read(1024, buf)
          f.write(buf)
        end
        s.rewind
      else
        f.write(s)
      end
    end
    raw
  end
end

if ENV["ORCA_API_WRITE_RESPONSE"]
  OrcaApi::OrcaApi.prepend(CallWithWriteResponse)
end
