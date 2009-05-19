require 'puppet'
require 'puppet/daemon'
require 'puppet/application'
require 'puppet/node/catalog'
require 'puppet/indirector/catalog/queue'
require 'puppet/util'


# BACKPORT - this method should be removed when merged into master.
class Puppet::Util::Settings
    # Generate the list of valid arguments, in a format that OptionParser can
    # understand, and add them to the passed option list.
    def optparse_addargs(options)
        # Add all of the config parameters as valid options.
        self.each { |name, element|
            options << element.optparse_args
        }

        return options
    end
end

# BACKPORT - this method should be removed when merged into master.
class Puppet::Util::Settings::CElement
    # get the arguments in OptionParser format
    def optparse_args
        if short
            ["--#{name}", "-#{short}", desc, :REQUIRED]
        else
            ["--#{name}", desc, :REQUIRED]
        end
    end
end

class Puppet::Util::Settings::CBoolean
    def optparse_args
        if short
            ["--[no-]#{name}", "-#{short}", desc, :NONE ]
        else
            ["--[no-]#{name}", desc, :NONE]
        end
    end
end

Puppet::Application.new(:puppetqd) do
    extend Puppet::Daemon

    should_parse_config

    extend Puppet::Util

    preinit do
        Puppet::Util::Log.newdestination(:console)
        # This exits with exit code 1
        trap(:INT) do
            $stderr.puts "Caught SIGINT; shutting down"
            exit(1)
        end

        # This is a normal shutdown, so code 0
        trap(:TERM) do
            $stderr.puts "Caught SIGTERM; shutting down"
            exit(0)
        end

        {
            :verbose => false,
            :debug => false
        }.each do |opt,val|
            options[opt] = val
        end

        @args = {}
    end

    option("--debug","-d")
    option("--verbose","-v")

    command(:main) do
        Puppet.notice "Starting puppetqd %s" % Puppet.version

        Puppet::Node::Catalog::Queue.subscribe do |catalog|
            # Once you have a Puppet::Node::Catalog instance, calling save() on it should suffice
            # to put it through to the database via its active_record indirector (which is determined
            # by the terminus_class = :active_record setting above)
            benchmark(:notice, "Processing queued catalog for %s" % catalog.name) do
                begin
                    catalog.save
                rescue => detail
                    puts detail.backtrace if Puppet[:trace]
                    Puppet.err "Could not save queued catalog for %s: %s" % [catalog.name, detail]
                end
            end
        end
        daemonize if Puppet[:daemonize]

        Thread.list.each { |thread| thread.join }
    end

    # This is the main application entry point.
    # BACKPORT - this method should be removed when merged into master.
    # This method had to be added because Puppet.settings.parse takes no
    # arguments in master but requires an argument in 0.24.x.
    def run
        run_preinit
        parse_options
        Puppet.settings.parse(Puppet[:config]) if should_parse_config? and File.exist?(Puppet[:config])
        run_setup
        run_command
    end

    # Handle the logging settings.
    def setup_logs
        if options[:debug] or options[:verbose]
            Puppet::Util::Log.newdestination(:console)
            if options[:debug]
                Puppet::Util::Log.level = :debug
            else
                Puppet::Util::Log.level = :info
            end
        end

        unless options[:setdest]
            Puppet::Util::Log.newdestination(:syslog)
        end
    end

    setup do
        unless Puppet.features.stomp?
            raise ArgumentError, "Could not load 'stomp', which must be present for queueing to work"
        end

        setup_logs

        if Puppet.settings.print_configs?
            exit(Puppet.settings.print_configs ? 0 : 1)
        end

        Puppet::Node::Catalog.terminus_class = :active_record

        # We want to make sure that we don't have a cache
        # class set up, because if storeconfigs is enabled,
        # we'll get a loop of continually caching the catalog
        # for storage again.
        Puppet::Node::Catalog.cache_class = nil
    end
end
