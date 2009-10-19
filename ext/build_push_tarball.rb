#!/usr/bin/ruby
#
# = Synopsis
#
# Create a tarball with a catalog and needed files for a given node.
#
# = Usage
#
#   build_push_tarball <host>
#
# = Description
#
# This script forces a catalog compile for a given node, extracts all of the file paths
# from the catalog, and makes a tarball of those files and the catalog.  This tarball
# can then be pushed to the client, where it can be used on the client with no
# communication to the server.
#
# = Options
#
# help::
#   Print this help message
#
# = Author
#
# Luke Kanies
#
# = Copyright
#
# Copyright (c) 2009 Reductive Labs, Inc.
# Licensed under the GPL2

require 'puppet'
require 'puppet/application'

Puppet::Application.new(:build_push_tarball) do

    should_parse_config

    attr_accessor :args

    def build_node_tarball(node)
        Dir.mkdir(node)
        Dir.chdir(node) do
            catalog = compile(node)

            extract_files_from_catalog(node, catalog)

            write_catalog(catalog)
        end

        mk_tarball(node)
        puts "Tarball for %s should be untarred directly into /etc/puppet"
    end

    def compile(node)
        Puppet::Util::Log.newdestination :console
        raise ArgumentError, "Cannot render compiled catalogs without json support" unless Puppet.features.json?
        begin
            unless catalog = Puppet::Resource::Catalog.find(node)
                raise "Could not compile catalog for #{node}" % node)
            end

            return catalog
        rescue => detail
            $stderr.puts detail
            exit(30)
        end
    end

    def extract_files_from_catalog(node, catalog)
        Dir.mkdir("files")
        Dir.chdir("files") do
            catalog.vertices.find_all { |res| res.type == "File" and ! res[:source].nil? }.each do |file|
                sources = Array(file[:source])
                c = sources.find do |source|
                    uri = URI.parse(source)
                    path = uri.path.sub(/^#{File::SEPARATOR}+/, '')
                    next unless content = Puppet::FileServing::Content.find(source)
                    File.open(path, "w") { |f|
                        f.print content.content
                    }
                    content # so we end once we've found something
                end
                unless c
                    raise "Could not find file for #{res.title} in #{sources.join(", ")}a"
                end
                file[:source] = "/etc/puppet/files/#{path}"
            end
        end
    end

    def mk_tarball(node)
        output = %x{tar czf #{node}.tgz #{node} 2>&1}
        unless $? == 0
            raise "Could not make tarball for #{node}: #{output}"
        end
    end

    def write_catalog(catalog)
        File.open("catalog.json", "w") { |f| f.print catalog.render(:pson) }
    end

    preinit do
        # Do an initial trap, so that cancels don't get a stack trace.
        trap(:INT) do
            $stderr.puts "Cancelling startup"
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
        raise "Node name must be specified" unless node_name = ARGV.shift
    end

    setup do
        if Puppet.settings.print_configs?
            exit(Puppet.settings.print_configs ? 0 : 1)
        end

        Puppet.settings.use :main, :puppetmasterd, :ssl

        # We need to specify a ca location for things to work, but
        # until the REST cert transfers are working, it needs to
        # be local.
        Puppet::SSL::Host.ca_location = :local

        Puppet::Resource::Catalog.terminus_class = :rest
        Puppet::Resource::Catalog.cache_class = :yaml

        Puppet::Node::Facts.terminus_class = :facter

        # We need tomake the client either way, we just don't start it
        # if --no-client is set.
        @agent = Puppet::Agent.new(Puppet::Configurer)

        enable_disable_client(@agent) if options[:enable] or options[:disable]

        @daemon.agent = agent if options[:client]

        # It'd be nice to daemonize later, but we have to daemonize before the
        # waitforcert happens.
        if Puppet[:daemonize]
            @daemon.daemonize
        end

        host = Puppet::SSL::Host.new
        cert = host.wait_for_cert(options[:waitforcert])

        @objects = []

        # This has to go after the certs are dealt with.
        if Puppet[:listen]
            unless options[:onetime]
                setup_listen
            else
                Puppet.notice "Ignoring --listen on onetime run"
            end
        end
    end
end
