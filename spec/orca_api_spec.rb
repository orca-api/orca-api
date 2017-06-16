require "spec_helper"

RSpec.describe OrcaApi do
  describe 'VERSION' do
    it do
      expect(OrcaApi::VERSION).not_to be nil
    end
  end
end
