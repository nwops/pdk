if ENV['COVERAGE'] == 'yes'
  require 'coveralls'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
    Coveralls::SimpleCov::Formatter,
  ]
  SimpleCov.start do
    track_files 'lib/**/*.rb'

    add_filter '/spec'

    # do not track vendored files
    add_filter '/lib/pdk/util/windows'
    add_filter '/vendor'
    add_filter '/.vendor'

    # do not track gitignored files
    # this adds about 4 seconds to the coverage check
    # this could definitely be optimized
    add_filter do |f|
      # system returns true if exit status is 0, which with git-check-ignore means file is ignored
      system("git check-ignore --quiet #{f.filename}")
    end
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pdk'
require 'pdk/cli'
require 'tempfile'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

analytics_config = nil

RSpec.shared_context :stubbed_logger do
  let(:logger) { instance_double('PDK::Logger').as_null_object }

  before(:each) do |example|
    allow(PDK).to receive(:logger).and_return(logger) if example.metadata[:use_stubbed_logger]
  end
end

RSpec.configure do |c|
  c.define_derived_metadata do |metadata|
    metadata[:use_stubbed_logger] = true unless metadata.key?(:use_stubbed_logger)
  end

  c.include_context :stubbed_logger

  c.before(:suite) do
    analytics_config = Tempfile.new('analytics.yml')
    analytics_config.write(YAML.dump(disabled: true))
    analytics_config.close
    ENV['PDK_ANALYTICS_CONFIG'] = analytics_config.path
  end

  c.after(:suite) do
    analytics_config.unlink
  end

  # This should catch any tests where we are not mocking out the actual calls to Rubygems.org
  c.before(:each) do
    allow(Gem::SpecFetcher).to receive(:fetcher).and_raise('Unmocked call to Gem::SpecFetcher.fetcher!')
    ENV['PDK_DISABLE_ANALYTICS'] = 'true'
  end

  c.add_setting :root
  c.root = File.dirname(__FILE__)
end

RSpec.shared_context :validators do
  let(:validators) do
    [
      PDK::Validate::MetadataValidator,
      PDK::Validate::YAMLValidator,
      PDK::Validate::PuppetValidator,
      PDK::Validate::RubyValidator,
      PDK::Validate::TasksValidator,
    ]
  end
end
