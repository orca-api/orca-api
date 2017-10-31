#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "orca_api"
require "pp"

########################################################################
## 基本設定

host = ENV["ORCA_API_HOST"] || "localhost"
port = ENV["ORCA_API_PORT"] || 8000

# Ginbeeではアカウント名はチェックしないためorca等、任意のものでよい。
account = ENV["ORCA_API_ACCOUNT"] || "ormaster"
password = ENV["ORCA_API_PASSWORD"] || "ormaster"

# https://www.orca.med.or.jp/receipt/use/glserver_ssl_client_verification2.html に従って作成した証明書を想定
ca_file = ENV["ORCA_API_CA_FILE"]
cert_path = ENV["ORCA_API_CERT_PATH"]
key_path = ENV["ORCA_API_KEY_PATH"]

########################################################################
## 接続

authentications = []

# SSLクライアント認証
if [ca_file, cert_path, key_path].all? { |s| s && File.exist?(s) }
  ssl_auth = OrcaApi::OrcaApi::SslClientAuthentication.new(ca_file, cert_path, key_path)
  authentications.push(ssl_auth)
end

# BASIC認証
basic_auth = OrcaApi::OrcaApi::BasicAuthentication.new(account, password)
authentications.push(basic_auth)

@orca_api = OrcaApi::OrcaApi.new(host, authentications, port)

# デバッグ
if ENV["ORCA_API_DEBUG"]
  @orca_api.debug_output = $stdout
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
  pp(hash)
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
    pp result.body
  end
end

########################################################################
## モンキーパッチ

# 自動テストのための日レセAPIのレスポンスを格納したファイルを
# spec/fixtures/orca_api_responses 以下に生成するためのモンキーパッチ
module CallWithWriteResponse
  def call(path, params: {}, body: nil, http_method: :post)
    raw = super
    res =
      begin
        OrcaApi::Result.new(raw, false)
      rescue
        OrcaApi::FormResult.new(raw)
      end

    if res.body["Orca_Uid"]
      orca_uid = res.body["Orca_Uid"]
      res.body["Orca_Uid"] = "c585dc3e-fa42-4f45-b02f-5a4166d0721d"
      begin
        s = JSON.pretty_generate(res.raw)
      ensure
        res.body["Orca_Uid"] = orca_uid
      end
    else
      s = JSON.pretty_generate(res.raw)
    end
    parts = []
    parts << path[1..-1].gsub("/", "_")
    if res["Request_Number"]
      parts << res["Request_Number"]
    end
    if res["Request_Mode"]
      parts << res["Request_Mode"]
    end
    if !res.ok?
      parts << res.api_result
    end
    fixture_path = File.expand_path("../../spec/fixtures/orca_api_responses/#{parts.join('_')}.json", __FILE__)
    File.open(fixture_path, "w") do |f|
      f.puts(s)
    end
    res.raw
  end
end

if ENV["ORCA_API_WRITE_RESPONSE"]
  OrcaApi::OrcaApi.prepend(CallWithWriteResponse)
end
