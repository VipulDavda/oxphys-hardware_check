require 'spec_helper'
describe 'hardware_check' do

  context 'with defaults for all parameters' do
    it { should contain_class('hardware_check') }
  end
end
