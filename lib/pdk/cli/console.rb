
module PDK::CLI
  @console_cmd = @base_cmd.define_command do
    name 'console'
    usage _('console [console_options]')
    summary _('Start a session of the puppet console.')
    default_subcommand 'help'
    description _(<<-EOF
The pdk console runs a interactive session of the puppet debugger tool to test out snippets of code, run
language evaluations, datatype prototyping and much more.  A virtual playground for your puppet code!
For usage details see the puppet debugger docs at https://docs.puppet-debugger.com.

EOF
    )   
    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)
    
    # we have to skip option parsing because it is expected the user
    # will be passing additional args that are passed to the debugger
    skip_option_parsing

    # TODO using -h or --help skips the pdk help and passes to puppet debugger help
    run do |opts, args, _cmd| 
      PDK::CLI::Util.ensure_in_module!(
        message:   _('Console can only be run from inside a valid module directory'),
        log_level: :info,
      )

      processed_options, processed_args = process_opts(args)
      PDK::CLI::Util.validate_puppet_version_opts(processed_options)

      PDK::CLI::Util.analytics_screen_view('console', args)

      # TODO figure out if we need to remove default configs set by puppet
      # so it is scoped for the module only
      # "--environmentpath"...
      flags = PDK::Util.in_module_root? ? ["--basemodulepath=#{base_module_path}"] : []
      debugger_args = ['debugger'] + processed_args + flags
      result = run_in_module(processed_options, debugger_args)

      exit result[:exit_code]
    end

    # @return [Array] - array of split options [{:"puppet-version"=>"6.9.0"}, ['--loglevel=debug']]
    # options are for the pdk and debugger pass through
    def process_opts(opts)
      args = opts.map do |e| 
        if e.match?(/\A-{2}puppet|pe\-version|dev/)
          value = e.split('=') 
          value.count < 2 ? value + [""] : value  
        end
      end
      args = args.compact.to_h  
      # symbolize keys
      args = args.inject({}){|memo,(k,v)| memo[k.sub('--', '').to_sym] = v; memo}
      processed_args = opts.map {|e|  e unless e.match?(/\A-{2}puppet|pe\-version|dev/)  }.compact
      [args, processed_args]
    end

    # @param opts [Hash] - the options passed into the CRI command
    # @param bundle_args [Array] array of bundle exec args and puppet debugger args
    # @return [Hash] - a command result hash
    def run_in_module(opts, bundle_args)
      output = opts[:debug].nil?
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts, output)
      gemfile_env = PDK::Util::Bundler::BundleHelper.gemfile_env(puppet_env[:gemset])
      desired_ruby_version = PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
      ruby = PDK::Util::RubyVersion.instance(puppet_env[:ruby_version])
      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

      debugger_args = ['exec', 'puppet'] + bundle_args
      command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, *debugger_args).tap do |c|  
        c.context = :pwd
        c.update_environment(gemfile_env)
      end
      command.execute!
    end

     # @return [String] - the basemodulepath of the fixtures and modules from the current module
     # also includes ./modules in case librarian puppet is used 
     def base_module_path
      base_module_path = File.join(PDK::Util.module_fixtures_dir, 'modules')
      "#{base_module_path}:#{File.join(PDK::Util.module_root, 'modules')}"
    end
  end
end
