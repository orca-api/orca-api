require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::UserService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:response_data) { parse_json(response_json) }

  describe "#list" do
    let(:response_json) { load_orca_api_response("orca101_manageusersv2_01.json") }

    it "API呼び出しが正しいこと" do
      expect(orca_api).to receive(:call).with("/orca101/manageusersv2",
                                              body: {
                                                "manageusersreq" => {
                                                  "Request_Number" => "01",
                                                  "Base_Date" => ""
                                                }
                                              }).and_return(response_json)
      service.list
    end

    it "base_date引数を指定する" do
      expect(orca_api).to receive(:call).with("/orca101/manageusersv2",
                                              body: {
                                                "manageusersreq" => {
                                                  "Request_Number" => "01",
                                                  "Base_Date" => "2018-01-22"
                                                }
                                              }).and_return(response_json)
      service.list "2018-01-22"
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
                                                    "Group_Number" => "9",
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
