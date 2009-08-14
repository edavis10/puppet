require 'puppet'
require 'puppet/application'
require 'puppet/network/handler'
require 'puppet/network/client'

Puppet::Application.new(:main) do

    should_parse_config

    option("--debug","-d")
    option("--verbose","-v")

    option("--logdest LOGDEST", "-l") do |arg|
        begin
            Puppet::Util::Log.newdestination(arg)
            options[:logset] = true
        rescue => detail
            $stderr.puts detail.to_s
        end
    end

    # This is the main application entry point
    def run
        exit_on_fail("parse options") { parse_options(true) } # This just parses up to the app name

        raise ArgumentError, "Application name not provided" unless app_name = ARGV.shift
        begin
            require "puppet/application/#{app_name}"
        rescue MissingSourceFile => details
            raise ArgumentError, "Could not load application #{app_name}: %s" % details
        end

        raise ArgumentError, "Could not find application #{app_name}" unless app = Puppet::Application[app_name]
        puts "got this far"

        exit_on_fail("initialize #{app_name}") { app.run_preinit }
        exit_on_fail("parse options for #{app_name}") { app.parse_options }
        exit_on_fail("parse configuration file for #{app_name}") { Puppet.settings.parse } # we always parse the config file
        exit_on_fail("prepare for execution for #{app_name}") { app.run_setup }

        unless method = option_method || ARGV.shift
            raise ArgumentError, "No method name provided; see --help"
        end

        app.send(method, *ARGV)
    end

    setup do
        if Puppet.settings.print_configs?
            exit(Puppet.settings.print_configs ? 0 : 1)
        end

        unless options[:logset]
            Puppet::Util::Log.newdestination(:console)
        end

        trap(:INT) do
            $stderr.puts "Exiting"
            exit(1)
        end

        if options[:debug]
            Puppet::Util::Log.level = :debug
        elsif options[:verbose]
            Puppet::Util::Log.level = :info
        end
    end
end
