require 'pdk/util/bundler'
require 'spec_helper'
require 'rspec-benchmark'

RSpec.describe 'bundler performance' do
  include RSpec::Benchmark::Matchers

  let(:bundler) { PDK::Util::Bundler::BundleHelper.new }

  it '#installed?' do
    expect { bundler.installed? }.to perform_under(1300).ms
  end
end
