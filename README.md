# orca_api

orca_apiは、[日医標準レセプトソフト](https://www.orca.med.or.jp/receipt/)が提供している[API](https://www.orca.med.or.jp/receipt/tec/api/)をRubyから利用するためのライブラリです。

## 使い方

 * [基本設計書](https://github.com/medley-inc/orca-api/wiki/%E5%9F%BA%E6%9C%AC%E8%A8%AD%E8%A8%88%E6%9B%B8)

## 開発者向け情報

### 必要なソフトウェア

 * ruby 2.3.4
 * bundler 1.15.1

### セットアップ

```shell
git clone https://github.com/medley-inc/orca_api.git
cd orca_api
bin/setup
```

### テスト実行

```shell
bundle exec rake spec
```

### インストール

```shell
bundle exec rake install
```
