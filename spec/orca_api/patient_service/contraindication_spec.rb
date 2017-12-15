require "spec_helper"
require_relative "../shared_examples"

RSpec.describe OrcaApi::PatientService::Contraindication, orca_api_mock: true do
  let(:service) { described_class.new(orca_api) }
  let(:orca_uid) { SecureRandom.uuid }
  let(:patient_id) { "00064" }

  describe "#get" do
    context "正常系" do
      it "call_orca12_patientmodv37_01の戻り値を返す" do
        result = double "Result", :ok? => true, :locked? => false, orca_uid: orca_uid
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { result }
        expect(service).to receive(:call_orca12_patientmodv37_99).with(result)
        expect(service.get(patient_id)).to eq result
      end
    end

    context "異常系" do
      it "orca_uidが発行されていればcall_orca12_patientmodv37_99を呼び出す" do
        result = double "Result", :ok? => false, :locked? => false, orca_uid: orca_uid
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { result }
        expect(service).to receive(:call_orca12_patientmodv37_99).with(result)
        expect(service.get(patient_id)).to eq result
      end

      it "orca_uidが発行されていなければcall_orca12_patientmodv37_99を呼び出さない" do
        result = double "Result", :ok? => false, :locked? => false
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { result }
        expect(service).to_not receive(:call_orca12_patientmodv37_99)
        expect(service.get(patient_id)).to eq result
      end

      it "他端末使用中であればcall_orca12_patientmodv37_99を呼び出さない" do
        result = double "Result", :ok? => false, :locked? => true, orca_uid: orca_uid
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { result }
        expect(service).to_not receive(:call_orca12_patientmodv37_99)
        expect(service.get(patient_id)).to eq result
      end
    end

    it "例外が起こってもunlock_orca12_patientmodv37を呼び出す" do
      allow(service).to receive(:call_orca12_patientmodv37_01) { raise "Something happen" }
      expect(service).to receive(:unlock_orca12_patientmodv37).with(nil)
      expect { service.get(patient_id) }.to raise_error "Something happen"
    end
  end

  describe '#update' do
    context "正常系" do
      it "call_orca12_patientmodv37_02の戻り値を返す" do
        params = {
          "Contra_Mode" => "Modify",
          "Patient_Contra_Info" => [
            { "Medication_Code" => "610463147" }
          ]
        }
        first_result = double "First Result", :ok? => true
        second_result = double "Second Result", :ok? => true
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { first_result }
        expect(service).to receive(:call_orca12_patientmodv37_02).with(params, first_result) { second_result }
        expect(service).to_not receive(:call_orca12_patientmodv37_99)
        expect(service.update(patient_id, params)).to eq second_result
      end
    end

    context "異常系" do
      it "call_orca12_patientmodv37_01が失敗したらcall_orca12_patientmodv37_02を呼び出さない" do
        params = {
          "Contra_Mode" => "Modify",
          "Patient_Contra_Info" => [
            { "Medication_Code" => "610463147" }
          ]
        }
        first_result = double "First Result", :ok? => false, :locked? => true
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { first_result }
        expect(service).to_not receive(:call_orca12_patientmodv37_02)
        expect(service).to_not receive(:call_orca12_patientmodv37_99)
        expect(service.update(patient_id, params)).to eq first_result
      end

      it "call_orca12_patientmodv37_02が失敗したらcall_orca12_patientmodv37_99を呼び出す" do
        params = {
          "Contra_Mode" => "Modify",
          "Patient_Contra_Info" => [
            { "Medication_Code" => "610463147" }
          ]
        }
        first_result  = double "First Result", :ok? => true, :locked? => false, orca_uid: orca_uid
        second_result = double "Second Result", :ok? => false
        expect(service).to receive(:call_orca12_patientmodv37_01).with(patient_id) { first_result }
        expect(service).to receive(:call_orca12_patientmodv37_02).with(params, first_result) { second_result }
        expect(service).to receive(:call_orca12_patientmodv37_99).with(first_result)
        expect(service.update(patient_id, params)).to eq second_result
      end
    end
  end
end
