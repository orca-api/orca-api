# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientService do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
  let(:patient_service) { described_class.new(orca_api) }

  describe "#get" do
    let(:patient_id) { 1 }
    let(:patient_information) { spy("OrcaApi::PatientInformation") }
    let(:health_public_insurance) { spy("OrcaApi::HealthPublicInsurance") }

    context "患者情報のみ取得する" do
      subject { patient_service.get(patient_id) }

      before do
        attributes = load_orca_api_response_json("orca12_patientmodv31_01.json").first[1]["Patient_Information"]
        expect(OrcaApi::PatientInformation).to receive(:new).with(attributes).and_return(patient_information).once

        count = 0
        expect(orca_api).to receive(:call).twice { |path, body: {}|
          case count
          when 0
            expect(path).to eq("/orca12/patientmodv31")

            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("01")

            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Patient_Mode"]).to eq("Modify")
            expect(req["Orca_Uid"]).to eq("")
          when 1
            expect(path).to eq("/orca12/patientmodv31")

            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("99")

            res01 = load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_01.json")["patientmodres"]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          end
          count += 1

          load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_#{req["Request_Number"]}.json")
        }
      end

      it { is_expected.to eq(patient_information) }
    end

    context "関連情報として患者保険・公費情報も取得する" do
      subject { patient_service.get(patient_id, associations: [:health_public_insurance]) }

      before do
        attributes = load_orca_api_response_json("orca12_patientmodv31_01.json").first[1]["Patient_Information"]
        expect(OrcaApi::PatientInformation).to receive(:new).with(attributes).and_return(patient_information).once

        attributes = load_orca_api_response_json("orca12_patientmodv32_01.json").first[1]
        expect(OrcaApi::HealthPublicInsurance).to receive(:new).with(attributes).and_return(health_public_insurance).once

        count = 0
        expect(orca_api).to receive(:call).exactly(4) { |path, body: {}|
          case count
          when 0
            expect(path).to eq("/orca12/patientmodv31")

            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("01")

            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Patient_ID"]).to eq(patient_id.to_s)
            expect(req["Patient_Mode"]).to eq("Modify")
            expect(req["Orca_Uid"]).to eq("")
          when 1
            expect(path).to eq("/orca12/patientmodv31")

            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("99")

            res01 = load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_01.json")["patientmodres"]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Patient_ID"]).to eq(res01["Patient_Information"]["Patient_ID"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          when 2
            expect(path).to eq("/orca12/patientmodv32")

            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("01")

            expect(req["Karte_Uid"]).to eq("karte_uid")
            expect(req["Orca_Uid"]).to eq("")
            expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)
          when 3
            expect(path).to eq("/orca12/patientmodv32")

            req = body["patientmodreq"]
            expect(req["Request_Number"]).to eq("99")

            res01 = load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_01.json").first[1]
            expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
            expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
            expect(req["Patient_Information"]).to eq(res01["Patient_Information"])
          end
          count += 1

          load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_#{req["Request_Number"]}.json")
        }
      end

      it { is_expected.to eq(patient_information) }

      it do
        subject
        expect(patient_information).to have_received("health_public_insurance=").with(health_public_insurance).once
      end
    end
  end

  describe "#get_health_public_insurance" do
    let(:patient_id) { 1 }
    let(:health_public_insurance) { spy("OrcaApi::HealthPublicInsurance") }

    subject { patient_service.get_health_public_insurance(patient_id) }

    before do
      attributes = load_orca_api_response_json("orca12_patientmodv32_01.json").first[1]
      expect(OrcaApi::HealthPublicInsurance).to receive(:new).with(attributes).and_return(health_public_insurance).once

      count = 0
      expect(orca_api).to receive(:call).twice { |path, body: {}|
        case count
        when 0
          expect(path).to eq("/orca12/patientmodv32")

          req = body["patientmodreq"]
          expect(req["Request_Number"]).to eq("01")

          expect(req["Karte_Uid"]).to eq("karte_uid")
          expect(req["Orca_Uid"]).to eq("")
          expect(req["Patient_Information"]["Patient_ID"]).to eq(patient_id.to_s)
        when 1
          expect(path).to eq("/orca12/patientmodv32")

          req = body["patientmodreq"]
          expect(req["Request_Number"]).to eq("99")

          res01 = load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_01.json").first[1]
          expect(req["Karte_Uid"]).to eq(res01["Karte_Uid"])
          expect(req["Orca_Uid"]).to eq(res01["Orca_Uid"])
          expect(req["Patient_Information"]).to eq(res01["Patient_Information"])
        end
        count += 1

        load_orca_api_response_json("#{path[1..-1].gsub("/", "_")}_#{req["Request_Number"]}.json")
      }
    end

    it { is_expected.to eq(health_public_insurance) }
  end
end
