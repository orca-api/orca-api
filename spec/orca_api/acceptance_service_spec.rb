require "spec_helper"
require_relative "shared_examples"

RSpec.describe OrcaApi::AcceptanceService, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }

  describe "#list" do
    let(:response_json) { load_orca_api_response("api01rv2_acceptlstv2_03.json") }

    it "ListResultを返すこと" do
      expect_data = [
        {
          path: "/api01rv2/acceptlstv2",
          params: {
            class: "03",
          },
          body: {
            "=acceptlstreq" => {},
          },
          response: response_json,
        },
      ]
      expect_orca_api_call(expect_data, binding)

      result = service.list

      expect(result.ok?).to be true

      response_data = parse_json(expect_data.last[:response])
      expect(result.acceptance_date).to eq response_data["acceptlstres"]["Acceptance_Date"]
      expect(result.list).to eq response_data["acceptlstres"]["Acceptlst_Information"]
    end

    context "with arguments" do
      it "klass" do
        expect_data = [
          {
            path: "/api01rv2/acceptlstv2",
            params: {
              class: "01",
            },
            body: {
              "=acceptlstreq" => {},
            },
            response: response_json,
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.list(klass: "01")

        expect(result.ok?).to be true
      end

      it "base_date" do
        expect_data = [
          {
            path: "/api01rv2/acceptlstv2",
            params: {
              class: "03",
            },
            body: {
              "=acceptlstreq" => {
                "Acceptance_Date" => "YYYY-MM-DD",
              },
            },
            response: response_json,
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.list(base_date: "YYYY-MM-DD")

        expect(result.ok?).to be true
      end

      it "department_code" do
        expect_data = [
          {
            path: "/api01rv2/acceptlstv2",
            params: {
              class: "03",
            },
            body: {
              "=acceptlstreq" => {
                "Department_Code" => "02",
              },
            },
            response: response_json,
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.list(department_code: "02")

        expect(result.ok?).to be true
      end

      it "physician_code" do
        expect_data = [
          {
            path: "/api01rv2/acceptlstv2",
            params: {
              class: "03",
            },
            body: {
              "=acceptlstreq" => {
                "Physician_Code" => "10002"
              },
            },
            response: response_json,
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.list(physician_code: "10002")

        expect(result.ok?).to be true
      end

      it "medical_information" do
        expect_data = [
          {
            path: "/api01rv2/acceptlstv2",
            params: {
              class: "03",
            },
            body: {
              "=acceptlstreq" => {
                "Medical_Information" => "02",
              },
            },
            response: response_json,
          },
        ]
        expect_orca_api_call(expect_data, binding)

        result = service.list(medical_information: "02")

        expect(result.ok?).to be true
      end
    end
  end

  describe "#create" do
    it "リクエスト内容が正しいこと" do
      args =
        service.new_builder.
        accept_at(Time.parse("2017-08-09T12:34:56")).
        patient_id("0001").
        department_code("01").
        physician_code("10001").
        medical_information("01").
        insurance_combination_number("0001").
        to_h

      expect_data = [
        {
          path: "/orca11/acceptmodv2",
          body: {
            "=acceptreq" => {
              "Request_Number" => "01",
              "Acceptance_Date" => "2017-08-09",
              "Acceptance_Time" => "12:34:56",
              "Patient_ID" => "0001",
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "Medical_Information" => "01",
              "HealthInsurance_Information" => {
                "Insurance_Combination_Number" => "0001"
              },
            },
          },
          result: "orca11_acceptmodv2_01.json",
        },
      ]
      expect_orca_api_call(expect_data, binding)

      result = service.create(args)

      expect(result.ok?).to be true
    end
  end

  describe "#update" do
    it "リクエスト内容が正しいこと" do
      acceptance_id = "00005"
      args =
        service.new_builder.
        accept_at(Time.parse("2018-03-19T15:38:53")).
        patient_id("5").
        department_code("01").
        physician_code("10001").
        medical_information("01").
        to_h

      expect_data = [
        {
          path: "/orca11/acceptmodv2",
          body: {
            "=acceptreq" => {
              "Request_Number" => "03",
              "Acceptance_Id" => acceptance_id,
              "Acceptance_Date" => "2018-03-19",
              "Acceptance_Time" => "15:38:53",
              "Patient_ID" => "5",
              "Department_Code" => "01",
              "Physician_Code" => "10001",
              "Medical_Information" => "01",
              "HealthInsurance_Information" => {},
            },
          },
          result: "orca11_acceptmodv2_03.json",
        },
      ]
      expect_orca_api_call(expect_data, binding)

      result = service.update(acceptance_id, args)

      expect(result.ok?).to be true
    end
  end

  describe "#destroy" do
    let(:acceptance_id) { SecureRandom.hex }
    let(:patient_id) { SecureRandom.hex }

    it "リクエスト内容が正しいこと" do
      expect_data = [
        {
          path: "/orca11/acceptmodv2",
          body: {
            "=acceptreq" => {
              "Request_Number" => "02",
              "Acceptance_Id" => acceptance_id,
              "Patient_ID" => patient_id,
            },
          },
          result: "orca11_acceptmodv2_01.json",
        },
      ]
      expect_orca_api_call(expect_data, binding)

      result = service.destroy(acceptance_id, patient_id)

      expect(result.ok?).to be true
    end
  end
end
