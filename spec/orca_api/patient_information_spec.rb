# coding: utf-8

require "spec_helper"

RSpec.describe OrcaApi::PatientInformation do
  describe ".new" do
    TARGET_CLASS = OrcaApi::PatientInformation
    RESPONSE_JSON = load_orca_api_response_json("orca12_patientmodv31_01.json").first[1]["Patient_Information"].freeze

    subject { OrcaApi::PatientInformation.new(attributes) }

    describe "日レセAPIのレスポンスから生成する" do
      let(:attributes) { RESPONSE_JSON }

      TARGET_CLASS.attribute_mappings.each do |json_name, attr_name|
        if TARGET_CLASS.struct_mappings.key?(attr_name)
          klass = TARGET_CLASS.struct_mappings[attr_name]
          describe attr_name do
            subject { super().send(attr_name) }

            it { is_expected.to be_instance_of(klass) }

            klass.attribute_mappings.each do |struct_json_name, struct_attr_name|
              its(struct_attr_name) { is_expected.to eq(attributes[json_name][struct_json_name]) }
            end
          end
        else
          its(attr_name) { is_expected.to eq(attributes[json_name]) }
        end
      end
    end

    describe "属性名を文字列で指定した属性値から生成する" do
      attributes_ = {}
      TARGET_CLASS.attribute_mappings.each do |json_name, attr_name|
        if TARGET_CLASS.struct_mappings.key?(attr_name)
          klass = TARGET_CLASS.struct_mappings[attr_name]

          attributes_[attr_name] = {}
          klass.attribute_mappings.each do |struct_json_name, struct_attr_name|
            attributes_[attr_name][struct_attr_name] = RESPONSE_JSON[json_name][struct_json_name]
          end

          describe attr_name do
            subject { super().send(attr_name) }

            it { is_expected.to be_instance_of(klass) }

            klass.attribute_mappings.each do |_, struct_attr_name|
              its(struct_attr_name) { is_expected.to eq(attributes[attr_name][struct_attr_name]) }
            end
          end
        else
          attributes_[attr_name] = RESPONSE_JSON[json_name]

          its(attr_name) { is_expected.to eq(attributes[attr_name]) }
        end
      end

      let(:attributes) { attributes_ }
    end

    describe "属性名をシンボルで指定した属性値から生成する" do
      attributes_ = {}
      TARGET_CLASS.attribute_mappings.each do |json_name, attr_name|
        if TARGET_CLASS.struct_mappings.key?(attr_name)
          klass = TARGET_CLASS.struct_mappings[attr_name]

          attributes_[attr_name.to_sym] = {}
          klass.attribute_mappings.each do |struct_json_name, struct_attr_name|
            attributes_[attr_name.to_sym][struct_attr_name.to_sym] = RESPONSE_JSON[json_name][struct_json_name]
          end

          describe attr_name.inspect do
            subject { super().send(attr_name) }

            it { is_expected.to be_instance_of(klass) }

            klass.attribute_mappings.each do |_, struct_attr_name|
              its(struct_attr_name) { is_expected.to eq(attributes[attr_name.to_sym][struct_attr_name.to_sym]) }
            end
          end
        else
          attributes_[attr_name.to_sym] = RESPONSE_JSON[json_name]

          its(attr_name) { is_expected.to eq(attributes[attr_name.to_sym]) }
        end
      end

      let(:attributes) { attributes_ }
    end
  end
end
