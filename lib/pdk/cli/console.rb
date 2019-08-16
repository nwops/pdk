
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
    skip_option_parsing

    run do |opts, args, _cmd| 
      # TODO pdk (ERROR): Unable to find a Puppet gem in current Ruby environment or from Rubygems.org.
      result = if PDK::Util.in_module_root?
        # exit 1 unless debugger_installed?

        PDK.logger.debug("Entering module level console mode")
        # puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
        # PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
        # ruby = PDK::Util::RubyVersion.instance(puppet_env[:ruby_version])
        # ruby_gem_cmd = File.join(ruby.bin_path, 'gem')
        # # PDK::Util::PuppetVersion.fetch_puppet_dev if opts[:'puppet-dev']
        # TODO subcommand to auto add .sync file
        # TODO subcommand to auto add nwops-debug to .fixtures
        # TODO wish debugger reflected name of current module, so I knew where I was
        # TODO wish puppet-debugger had a settings plugin
        # the bundle install command takes way too long!!!
        # PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])
        # gemfile_env = PDK::Util::Bundler::BundleHelper.gemfile_env(puppet_env[:gemset])
        # module spec helper puts the files here
        # r10k or librarian puppet will sometimes store modules here
        debugger_args = ['exec', 'puppet', 'debugger', "--basemodulepath=#{base_module_path}"]
        bundle_args = debugger_args + args
        command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, *bundle_args).tap do |c|  
          c.context = :pwd
          #c.update_environment(gemfile_env)
        end
        command.execute!
      else
        PDK.logger.debug("Entering global console mode")  
        exit 1 unless debugger_installed?      
        # which ruby does this use?
        puppet_cmd = File.join(Gem.bindir, 'puppet')
        PDK::CLI::Exec.execute_interactive("#{puppet_cmd} debugger " + args.join(' '))
      end
      # Error: Unknown Puppet subcommand 'debugger'
      # How to handle when the debugger is not installed?
      # how to handle when puppet option is incorrect?
      exit result[:exit_code]  
    end

    # @return [String] - the basemodulepath of the fixtures and modules from the current module
    def base_module_path
      base_module_path = File.join(PDK::Util.module_fixtures_dir, 'modules')
      "#{base_module_path}:#{File.join(PDK::Util.module_root, 'modules')}"
    end

    # @return [Boolean] true if the puppet-debugger gem was found in the gem specifications path
    def debugger_installed?
      # TODO this only checks the current ruby and not the requested ruby
      gem_cmd = File.join(File.dirname(Gem.ruby), 'gem')
      unless gem_installed?('puppet-debugger')
        PDK.logger.info _("The puppet-debugger gem is not installed, please run:\n#{gem_cmd} install puppet-debugger --user-install")
        return false
      end
      true
    end

    # def gem_installed?(name)
    #   gem_cmd = File.join(Gem.bindir, 'gem')
    #   # switch to using internal api instead of shelling out
    #   result = PDK::CLI::Exec.execute(gem_cmd, *["list", '-i', name])
    #   result[:stdout].chomp == 'true'
    # end

    # @return [Boolean] true if the named gem was found in the gem specifications path
    def gem_installed?(name)
      # this only checks the current ruby and not the requested ruby
      !Gem::Specification.latest_specs.find {|spec| spec.name.eql?(name) }.nil?
    end
  end
end
