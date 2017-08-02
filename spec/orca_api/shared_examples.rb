# coding: utf-8

require "spec_helper"

RSpec.shared_examples "orca_api_mock", orca_api_mock: true do
  let(:orca_api) { double("OrcaApi::OrcaApi", karte_uid: "karte_uid") }
end
