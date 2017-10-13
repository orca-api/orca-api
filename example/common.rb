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
  hash = keys.map { |key|
    [key, result[key]]
  }.to_h
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
