
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
    # PDK::CLI.puppet_version_options(self)
    # PDK::CLI.puppet_dev_option(self)             
    skip_option_parsing

    run do |opts, args, _cmd| 
      # insert_gem_paths
      # exit 1 unless debugger_installed? 
      flags = PDK::Util.in_module_root? ? ["--basemodulepath=#{base_module_path}"] : []
      # puppet_cmd = File.join(cache_bin_dir, 'puppet')
      debugger_args = ['debugger'] + args + flags
      result = run_in_module(opts, debugger_args)
      #run_debugger(debugger_args)
      
    end

    def run_in_module(opts, bundle_args)
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts, true)
      desired_ruby_version = PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
      ruby = PDK::Util::RubyVersion.instance(puppet_env[:ruby_version])
      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

      debugger_args = ['exec', 'puppet'] + bundle_args
      command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, *debugger_args).tap do |c|  
        #c.context = :pwd
        #c.update_environment(gemfile_env)
      end
      command.execute!
    end

    def run_debugger_as_command(puppet_cmd, debugger_args)
      command = PDK::CLI::Exec::InteractiveCommand.new(puppet_cmd, *debugger_args)
      command.execute!
    end

    # @
    def run_debugger(options)
      require 'puppet/application/debugger'
      require 'puppet/application'
      debugger_klass = Puppet::Application.find('debugger')
      command_line = Puppet::Util::CommandLine.new('puppet', options)
      debugger = debugger_klass.new(command_line)
      debugger.initialize_app_defaults
      debugger.run
    end

    # @return [String] path to the bin directory where the gems were installed 
    # ie. /opt/puppetlabs/pdk/share/cache/ruby/2.4.0/bin
    # This is for the currently running ruby
    # @note the cache directory has the puppet-debugger gem 
    def cache_bin_dir
      PDK::Util.package_install? ? File.join(PDK::Util.package_cachedir, 'ruby', '2.4.0', 'bin') : Gem.bindir
    end

    def base_ruby
      PDK::Util::RubyVersion.versions[PDK::Util::RubyVersion.active_ruby_version]
    end

    def insert_gem_paths
      gems_cache = [File.join(PDK::Util.cachedir, 'ruby', base_ruby), Gem.paths.home]
      gems_cache << File.join(PDK::Util.package_cachedir, 'ruby', base_ruby) if PDK::Util.package_install?

      Gem.paths = {
        'GEM_HOME' => Gem.paths.home,
        'GEM_PATH' => gems_cache.join(':')
      }
      PDK.logger.debug(Gem.paths.inspect)
    end

    def puppet_command
      dir = Gem::Specification.latest_specs.find {|spec| spec.name.eql?('puppet') }.bin_dir
      PDK.logger.debug(dir)
      File.join(dir, 'puppet')
    end

    # @return [String] - the basemodulepath of the fixtures and modules from the current module
    def base_module_path
      base_module_path = File.join(PDK::Util.module_fixtures_dir, 'modules')
      "#{base_module_path}:#{File.join(PDK::Util.module_root, 'modules')}"
    end

    # @return [Boolean] true if the puppet-debugger gem was found in the gem specifications path
    def debugger_installed?
      # TODO this only checks the current ruby and not the requested ruby
      begin
        require 'puppet/application/debugger'
        require 'puppet/application'
      rescue LoadError, Gem::MissingSpecError => e
        PDK.logger.debug(e.message)
        raise PDK::CLI::ExitWithError, _("The puppet-debugger gem is not installed, please run:\n#{gem_cmd} install puppet-debugger --user-install -N")
      end
      unless gem_installed?('puppet-debugger')
        raise PDK::CLI::ExitWithError, _("The puppet-debugger gem is not installed, please run:\n#{gem_cmd} install puppet-debugger --user-install -N")
      end
      true
    end

    def gem_cmd
      File.join(Gem.bindir, 'gem')
    end

    # @return [Boolean] true if the named gem was found in the gem specifications path
    def gem_installed?(name)
      # this only checks the current ruby and not the requested ruby
      !Gem::Specification.latest_specs.find {|spec| spec.name.eql?(name) }.nil?
    end
  end
end
