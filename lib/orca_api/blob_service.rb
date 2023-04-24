require_relative "service"
require "erb"
require "tempfile"

module OrcaApi
  # 大容量データを扱うサービスを表現したクラス
  #
  # 明細書やレセ電といった処理を実施した場合は、最終データとして印刷データ(pdf)、
  # およびレセ電データ(csv)を取得する必要がある。
  # これらのデータを取得する方法として大容量APIを利用する。
  # 大容量データを作成するAPIをリクエストした場合、原則以下の情報を返却する。
  #
  # ```ruby
  # {
  #   "Data_Id_Information" => [
  #     {
  #       "Data_Id" => "UID1", # pdf以外取得用ID
  #       "Print_Id" => "UID2", # pdf取得用ID
  #     }
  #   ]
  # }
  # ```
  #
  # この返却されたData_Id及びPrint_Idをgetメソッドに指定して該当データを取得する。
  #
  # ※ 大容量API個別対応について
  # パッチ提供◆日医標準レセプトソフト 5.0.0(第15回) (2017/10/24) 以降、
  # 大容量API(このパッチでは、病名マスタ一括取得および明細書帳票取得(レセプト))の対応をおこなったが、
  # 全ての定義体を無条件に適応すると、以下のミドルウエア以前のバージョンでは、日レセサービスが起動しなくなるため、
  # 一部ファイルは手動により適応する。(テスト環境でのテスト推奨)
  #
  # 適応ミドルバージョン
  # [ORCA-ANNOUNCE:04338] 日医標準レセプトソフト◆ミドルウェア更新(2017/10/16) 以降
  #
  # [install_modules.tgz](http://ftp01.orca.med.or.jp/pub/data/receipt/tec/api/haori/install_modules.tgz)
  #
  # プログラムの適用方法
  #
  #  * (1) tgzファイルを解凍する。
  #    * tar xvfz install_modules.tgz
  #  * (2) 修正定義体(ldファイル)を適用する。
  #    * sudo -u orca bash ./install_modules.sh
  #  * (3) 日レセを再起動する。
  #
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/18352 大容量データの取得について(大容量API)
  # @see http://cms-edit.orca.med.or.jp/_admin/preview_revision/19238#api6
  class BlobService < Service
    # 大容量データの取得
    #
    # @param [String] uid
    #   Data_IdまたはPrint_Id
    # @param [IO,nil] output_io (Temfile.new)
    #   レスポンスボディを格納するためのIO
    # @return [OrcaApi::BinaryResult]
    #   日レセからのレスポンス
    #   `output_io` 引数にIOを指定した場合、 `#raw` と `#body` には指定したIOが格納される。
    #   `output_io` 引数にnilを指定した場合は、`#raw` と `#body` にはレスポンスボディを格納した文字列が格納される。
    def get(uid, output_io = Tempfile.new(binmode: true))
      path = "/blobapi/#{uid}"
      BinaryResult.new(orca_api.call(path, http_method: :get, format: nil, output_io: output_io))
    end
  end
end
