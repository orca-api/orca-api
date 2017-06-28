require "spec_helper"

RSpec.describe OrcaApi do
  describe 'VERSION' do
    it { expect(OrcaApi::VERSION).to match(/\A\d+\.\d+\.\d+\z/) }
  end
end
