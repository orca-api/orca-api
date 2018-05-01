# ORCA API

[ORCA API](https://orca-api.github.io/)は、[日医標準レセプトソフト](https://www.orca.med.or.jp/receipt/)が提供している[API](https://www.orca.med.or.jp/receipt/tec/api/)をRubyから利用するためのライブラリです。

## 開発者向け情報

### 必要なソフトウェア

 * ruby 2.3.4以降
 * bundler 1.15.1

### セットアップ

```shell
git clone https://github.com/orca-api/orca-api.git
cd orca-api
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

### ライセンス

[Apache License 2.0](LICENSE)
