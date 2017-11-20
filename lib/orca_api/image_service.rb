require_relative "service"
require_relative "binary_result"

module OrcaApi
  # 画像データ取得API
  #
  # @see http://ftp.orca.med.or.jp/pub/data/receipt/tec/push-api/imageget.pdf
  class ImageService < Service
    # 帳票データに含まれるイメージIDを指定して、画像データをZIP圧縮したバイナリを取得し、それを含む `BinaryResult` オブジェクトを返す
    #
    # @param [String] image_id イメージID
    # @return [BinaryResult] 画像データをZIP圧縮したバイナリを格納した `BinaryResult` オブジェクト
    def get(image_id)
      BinaryResult.new(orca_api.call(
        "/api01rv2/imagegetv2'",
        body: {
          "data" => {
            "imagegetv2req" => {
              "Image_ID" => image_id,
            }
          }
        },
        &->(res) { res.body }
      ))
    end
  end
end
