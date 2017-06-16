require "spec_helper"

RSpec.describe OrcaApi do
  describe 'VERSION' do
    it { expect(OrcaApi::VERSION).not_to be nil }
  end
end
