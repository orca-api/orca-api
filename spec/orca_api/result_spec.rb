require "spec_helper"

RSpec.describe OrcaApi::Result do
  let(:haori_ok_response) {
    {
      "patientmodres" => {
        "Request_Number" => "01",
        "Response_Number" => "02",
        "Karte_Uid" => "karte_uid",
        "Orca_Uid" => "850a3c68-44a6-4306-a00e-f3306fdc6dad",
        "Information_Date" => "2017-06-29",
        "Information_Time" => "08:33:42",
        "Api_Result" => "000",
        "Api_Result_Message" => "検索処理終了",
        "Reskey" => "Acceptance_Info",
      }
    }
  }

  let(:haori_ng_response) {
    {
      "patientmodres" => {
        "Request_Number" => "01",
        "Response_Number" => "02",
        "Karte_Uid" => "karte_uid",
        "Orca_Uid" => "a2082aa7-2915-4e9b-91ee-e0c653767824",
        "Information_Date" => "2017-07-12",
        "Information_Time" => "21:57:27",
        "Api_Result" => "S20",
        "Api_Result_Message" => "選択項目があります。選択結果を返却してください。",
        "Reskey" => "Acceptance_Info",
      }
    }
  }

  let(:not_haori_ok_response) {
    {
      "patientinfores" => {
        "Information_Date" => "2017-06-28",
        "Information_Time" => "11:21:28",
        "Api_Result" => "00",
        "Api_Result_Message" => "処理終了",
        "Reskey" => "Patient Info",
      }
    }
  }

  let(:result) { described_class.new(response) }

  subject { result }

  context "HAORIの正常レスポンス" do
    let(:response) { haori_ok_response }

    its(:raw) { is_expected.to eq(response) }
    its(:body) { is_expected.to eq(response.first[1]) }
    its("ok?") { is_expected.to be true }
    its(:message) { is_expected.to eq("検索処理終了(000)") }

    %i(api_result api_result_message request_number response_number karte_uid orca_uid).each do |sym|
      it { is_expected.to be_respond_to(sym) }
    end

    its(:api_result) { is_expected.to eq("000") }
    its(:api_result_message) { is_expected.to eq("検索処理終了") }
    its(:request_number) { is_expected.to eq("01") }
    its(:response_number) { is_expected.to eq("02") }
    its(:karte_uid) { is_expected.to eq("karte_uid") }
    its(:orca_uid) { is_expected.to eq("850a3c68-44a6-4306-a00e-f3306fdc6dad") }
  end

  context "HAORIの異常レスポンス" do
    let(:response) { haori_ng_response }

    its(:raw) { is_expected.to eq(response) }
    its(:api_result) { is_expected.to eq("S20") }
    its(:api_result_message) { is_expected.to eq("選択項目があります。選択結果を返却してください。") }
    its(:request_number) { is_expected.to eq("01") }
    its(:response_number) { is_expected.to eq("02") }
    its(:karte_uid) { is_expected.to eq("karte_uid") }
    its(:orca_uid) { is_expected.to eq("a2082aa7-2915-4e9b-91ee-e0c653767824") }
    its("ok?") { is_expected.to be false }
    its(:message) { is_expected.to eq("選択項目があります。選択結果を返却してください。(S20)") }
  end

  context "HAORIではない正常レスポンス" do
    let(:response) { not_haori_ok_response }

    its(:raw) { is_expected.to eq(response) }
    its(:api_result) { is_expected.to eq("00") }
    its(:api_result_message) { is_expected.to eq("処理終了") }
    its("ok?") { is_expected.to be true }
    its(:message) { is_expected.to eq("処理終了(00)") }

    %w(request_number response_number karte_uid orca_uid).each do |name|
      describe name do
        it { expect { subject.send(name) }.to raise_error NoMethodError }
      end
    end
  end

  context "他端末使用中のレスポンス" do
    context "E90" do
      let(:response) {
        {
          "medicalv3res4" => {
            "Request_Number" => "01",
            "Response_Number" => "01",
            "Karte_Uid" => "karte_uid",
            "Information_Date" => "2017-08-30",
            "Information_Time" => "10:52:27",
            "Api_Result" => "E90",
            "Api_Result_Message" => "他端末使用中",
          }
        }
      }

      its(:raw) { is_expected.to eq(response) }
      its(:body) { is_expected.to eq(response.first[1]) }
      its("ok?") { is_expected.to be false }
      its("locked?") { is_expected.to be true }
      its(:message) { is_expected.to eq("他端末使用中(E90)") }
    end

    context "E9999" do
      let(:response) {
        {
          "incomev3res" => {
            "Information_Date" => "2017-10-19",
            "Information_Time" => "12:20:39",
            "Api_Result" => "E9999",
            "Api_Result_Message" => "他端末で使用中です。",
            "Request_Number" => "01",
            "Request_Mode" => "01",
            "Response_Number" => "01",
            "Karte_Uid" => "karte_uid",
            "Orca_Uid" => "877718f1-7dbc-4e08-bd2c-8788a858b3a2"
          }
        }
      }

      its(:raw) { is_expected.to eq(response) }
      its(:body) { is_expected.to eq(response.first[1]) }
      its("ok?") { is_expected.to be false }
      its("locked?") { is_expected.to be true }
      its(:message) { is_expected.to eq("他端末で使用中です。(E9999)") }
    end
  end
end
