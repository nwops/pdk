require 'spec_helper'

describe 'pdk console' do
  let(:test_cmd) { PDK::CLI.instance_variable_get(:@console_cmd) }

  it { expect(test_cmd).not_to be_nil }

  context 'packaged install' do
    include_context 'packaged install'

    it 'invokes console and exits zero' do
      expect { PDK::CLI.run(['console', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end

    it 'does not have debugger gem' do
      allow(Gem::Specification).to receive(:latest_specs).and_return([])
      expect { PDK::CLI.run(['console', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_nonzero
    end
  end

  context 'not packaged install' do
    include_context 'not packaged install'

    it 'invokes console and exits zero' do
      expect { PDK::CLI.run(['console', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end

    it 'does not have debugger gem' do
      allow(Gem::Specification).to receive(:latest_specs).and_return([])
      expect { PDK::CLI.run(['console', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_nonzero
    end
  end

  describe 'not in a module' do
    before(:each) do
      allow(PDK::Util).to receive(:in_module_root?).and_return(false)
    end

    it 'invokes console with options' do
      expect { PDK::CLI.run(['console', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end
  end

  describe 'in a module' do
    before(:each) do
      allow(PDK::Util).to receive(:in_module_root?).and_return(true)
    end

    it 'invokes console with options' do
      expect { PDK::CLI.run(['console', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end
  end


end
