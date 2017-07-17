# coding: utf-8

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

  describe "#raw" do
    let(:response) { haori_ok_response }

    subject { result.raw }

    it { is_expected.to eq(response) }
  end

  describe "#api_result" do
    subject { result.api_result }

    context "Api_Resultが000" do
      let(:response) { haori_ok_response }

      it { is_expected.to eq("000") }
    end

    context "Api_ResultがS20" do
      let(:response) { haori_ng_response }

      it { is_expected.to eq("S20") }
    end
  end

  describe "#ok?" do
    subject { result.ok? }

    context "Api_Resultが000" do
      let(:response) { haori_ok_response }

      it { is_expected.to be true }
    end

    context "Api_ResultがS20" do
      let(:response) { haori_ng_response }

      it { is_expected.to be false }
    end
  end

  describe "#api_result_message" do
    subject { result.api_result_message }

    context "Api_Result_Messageが検索処理終了" do
      let(:response) { haori_ok_response }

      it { is_expected.to eq("検索処理終了") }
    end
  end

  describe "#message" do
    subject { result.message }

    context "HAORIの正常" do
      let(:response) { haori_ok_response }

      it { is_expected.to eq("検索処理終了(000)") }
    end

    context "HAORIの異常" do
      let(:response) { haori_ng_response }

      it { is_expected.to eq("選択項目があります。選択結果を返却してください。(S20)") }
    end
  end
end
