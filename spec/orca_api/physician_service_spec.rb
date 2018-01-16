require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::PhysicianService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#list" do
    let(:response_json) { load_orca_api_response("api01rv2_system01lstv2_02.json") }

    before do
      body = {
        "system01_managereq" => {
          "Request_Number" => "02",
          "Base_Date" => base_date,
        }
      }
      expect(orca_api).to receive(:call).with("/api01rv2/system01lstv2", body: body).once.and_return(response_json)
    end

    shared_examples "結果が正しいこと" do
      its("ok?") { is_expected.to be true }
      its(:physician_information) { is_expected.to eq(response_data.first[1]["Physician_Information"]) }
    end

    context "引数を省略する" do
      let(:base_date) { "" }

      subject { service.list }

      include_examples "結果が正しいこと"
    end

    context "base_date引数を指定する" do
      let(:base_date) { "2017-07-25" }

      subject { service.list(base_date) }

      include_examples "結果が正しいこと"
    end
  end

  describe "#create" do
    let(:response_json) { load_orca_api_response("orca101_manageusersv2_02.json") }

    it "API呼び出しが正しいこと" do
      expect(orca_api).to receive(:call).with("/orca101/manageusersv2",
                                              body: {
                                                "manageusersreq" => {
                                                  "Request_Number" => "02",
                                                  "User_Information" => {
                                                    "User_Id" => "doctor",
                                                    "Group_Number" => "1",
                                                    "Unknown" => "Unknown",
                                                  }
                                                }
                                              }).and_return(response_json)
      service.create "User_Id" => "doctor",
                     "Group_Number" => "9",
                     "Unknown" => "Unknown"
    end
  end

  describe "#update" do
    let(:response_json) { load_orca_api_response("orca101_manageusersv2_03.json") }

    it "API呼び出しが正しいこと" do
      expect(orca_api).to receive(:call).with("/orca101/manageusersv2",
                                              body: {
                                                "manageusersreq" => {
                                                  "Request_Number" => "03",
                                                  "User_Information" => {
                                                    "User_Id" => "doctor",
                                                    "New_Full_Name" => "山田太郎",
                                                    "Unknown" => "Unknown",
                                                  }
                                                }
                                              }).and_return(response_json)
      service.update "doctor",
                     "New_Full_Name" => "山田太郎",
                     "Unknown" => "Unknown"
    end
  end

  describe "#destroy" do
    let(:response_json) { load_orca_api_response("orca101_manageusersv2_04.json") }

    it "API呼び出しが正しいこと" do
      expect(orca_api).to receive(:call).with("/orca101/manageusersv2",
                                              body: {
                                                "manageusersreq" => {
                                                  "Request_Number" => "04",
                                                  "User_Information" => {
                                                    "User_Id" => "doctor",
                                                  }
                                                }
                                              }).and_return(response_json)
      service.destroy "doctor"
    end
  end
end
