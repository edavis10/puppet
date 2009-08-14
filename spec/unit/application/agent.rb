#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/application/agent'
require 'puppet/network/server'

describe "agent app" do
    before :each do
        @agent_app = Puppet::Application[:agent]
        @agent_app.stubs(:puts)
        @daemon = stub_everything 'daemon'
        Puppet::Daemon.stubs(:new).returns(@daemon)
        @agent = stub_everything 'agent'
        Puppet::Agent.stubs(:new).returns(@agent)
        @agent_app.run_preinit
        Puppet::Util::Log.stubs(:newdestination)
        Puppet::Util::Log.stubs(:level=)

        Puppet::Node.stubs(:terminus_class=)
        Puppet::Node.stubs(:cache_class=)
        Puppet::Node::Facts.stubs(:terminus_class=)
    end

    it "should ask Puppet::Application to parse Puppet configuration file" do
        @agent_app.should_parse_config?.should be_true
    end

    it "should declare a main command" do
        @agent_app.should respond_to(:main)
    end

    it "should declare a onetime command" do
        @agent_app.should respond_to(:onetime)
    end

    it "should declare a preinit block" do
        @agent_app.should respond_to(:run_preinit)
    end

    describe "in preinit" do
        before :each do
            @puppetd.stubs(:trap)
        end

        it "should catch INT" do
            @agent_app.expects(:trap).with { |arg,block| arg == :INT }

            @agent_app.run_preinit
        end

        it "should set waitforcert to 120" do
            @agent_app.run_preinit

            @agent_app.options[:waitforcert].should == 120
        end

        it "should init client to true" do
            @agent_app.run_preinit

            @agent_app.options[:client].should be_true
        end

        it "should init fqdn to nil" do
            @agent_app.run_preinit

            @agent_app.options[:fqdn].should be_nil
        end

        it "should init serve to []" do
            @agent_app.run_preinit

            @agent_app.options[:serve].should == []
        end

    end

    describe "when handling options" do
        before do
            @old_argv = ARGV.dup
            ARGV.clear
        end

        after do
            ARGV.clear
            @old_argv.each { |a| ARGV << a }
        end

        [:centrallogging, :disable, :enable, :debug, :fqdn, :test, :verbose].each do |option|
            it "should declare handle_#{option} method" do
                @agent_app.should respond_to("handle_#{option}".to_sym)
            end

            it "should store argument value when calling handle_#{option}" do
                @agent_app.options.expects(:[]=).with(option, 'arg')
                @agent_app.send("handle_#{option}".to_sym, 'arg')
            end
        end

        it "should set an existing handler on server" do
            Puppet::Network::Handler.stubs(:handler).with("handler").returns(true)

            @agent_app.handle_serve("handler")
            @agent_app.options[:serve].should == [ :handler ]
        end

        it "should set client to false with --no-client" do
            @agent_app.handle_no_client(nil)
            @agent_app.options[:client].should be_false
        end

        it "should set onetime to ture with --onetime" do
            @agent_app.handle_onetime(nil)
            @agent_app.options[:onetime].should be_true
        end

        it "should set waitforcert to 0 with --onetime and if --waitforcert wasn't given" do
            @agent_app.explicit_waitforcert = false
            @agent_app.handle_onetime(nil)
            @agent_app.options[:waitforcert].should == 0
        end

        it "should not reset waitforcert with --onetime when --waitforcert is used" do
            @agent_app.explicit_waitforcert = true
            @agent_app.handle_onetime(nil)
            @agent_app.options[:waitforcert].should_not == 0
        end

        it "should set the log destination with --logdest" do
            @agent_app.options.stubs(:[]=).with { |opt,val| opt == :setdest }
            Puppet::Log.expects(:newdestination).with("console")

            @agent_app.handle_logdest("console")
        end

        it "should put the setdest options to true" do
            @agent_app.options.expects(:[]=).with(:setdest,true)

            @agent_app.handle_logdest("console")
        end

        it "should parse the log destination from ARGV" do
            ARGV << "--logdest" << "/my/file"

            Puppet::Util::Log.expects(:newdestination).with("/my/file")

            @agent_app.parse_options
        end

        it "should store the waitforcert options with --waitforcert" do
            @agent_app.options.expects(:[]=).with(:waitforcert,42)

            @agent_app.handle_waitforcert("42")
        end

        it "should mark explicit_waitforcert to true with --waitforcert" do
            @agent_app.options.stubs(:[]=)

            @agent_app.handle_waitforcert("42")
            @agent_app.explicit_waitforcert.should be_true
        end

        it "should set args[:Port] with --port" do
            @agent_app.handle_port("42")
            @agent_app.args[:Port].should == "42"
        end

    end

    describe "during setup" do
        before :each do
            @agent_app.options.stubs(:[])
            Puppet.stubs(:info)
            FileTest.stubs(:exists?).returns(true)
            Puppet.stubs(:[])
            Puppet.stubs(:[]).with(:libdir).returns("/dev/null/lib")
            Puppet.settings.stubs(:print_config?)
            Puppet.settings.stubs(:print_config)
            Puppet::SSL::Host.stubs(:ca_location=)
            Puppet::Transaction::Report.stubs(:terminus_class=)
            Puppet::Resource::Catalog.stubs(:terminus_class=)
            Puppet::Resource::Catalog.stubs(:cache_class=)
            Puppet::Node::Facts.stubs(:terminus_class=)
            @host = stub_everything 'host'
            Puppet::SSL::Host.stubs(:new).returns(@host)
            Puppet.stubs(:settraps)
        end

        describe "with --test" do
            before :each do
                Puppet.settings.stubs(:handlearg)
                @agent_app.options.stubs(:[]=)
            end

            it "should call setup_test" do
                @agent_app.options.stubs(:[]).with(:test).returns(true)
                @agent_app.expects(:setup_test)
                @agent_app.run_setup
            end

            it "should set options[:verbose] to true" do
                @agent_app.options.expects(:[]=).with(:verbose,true)
                @agent_app.setup_test
            end
            it "should set options[:onetime] to true" do
                @agent_app.options.expects(:[]=).with(:onetime,true)
                @agent_app.setup_test
            end
            it "should set options[:detailed_exitcodes] to true" do
                @puppetd.options.expects(:[]=).with(:detailed_exitcodes,true)
                @puppetd.setup_test
            end
            it "should set waitforcert to 0" do
                @agent_app.options.expects(:[]=).with(:waitforcert,0)
                @agent_app.setup_test
            end
        end

        it "should call setup_logs" do
            @agent_app.expects(:setup_logs)
            @agent_app.run_setup
        end

        describe "when setting up logs" do
            before :each do
                Puppet::Util::Log.stubs(:newdestination)
            end

            it "should set log level to debug if --debug was passed" do
                @agent_app.options.stubs(:[]).with(:debug).returns(true)

                Puppet::Util::Log.expects(:level=).with(:debug)

                @agent_app.setup_logs
            end

            it "should set log level to info if --verbose was passed" do
                @agent_app.options.stubs(:[]).with(:verbose).returns(true)

                Puppet::Util::Log.expects(:level=).with(:info)

                @agent_app.setup_logs
            end

            [:verbose, :debug].each do |level|
                it "should set console as the log destination with level #{level}" do
                    @agent_app.options.stubs(:[]).with(level).returns(true)

                    Puppet::Util::Log.expects(:newdestination).with(:console)

                    @agent_app.setup_logs
                end
            end

            it "should set syslog as the log destination if no --logdest" do
                @agent_app.options.stubs(:[]).with(:setdest).returns(false)

                Puppet::Util::Log.expects(:newdestination).with(:syslog)

                @agent_app.setup_logs
            end

        end

        it "should print puppet config if asked to in Puppet config" do
            @agent_app.stubs(:exit)
            Puppet.settings.stubs(:print_configs?).returns(true)

            Puppet.settings.expects(:print_configs)

            @agent_app.run_setup
        end

        it "should exit after printing puppet config if asked to in Puppet config" do
            Puppet.settings.stubs(:print_configs?).returns(true)

            lambda { @agent_app.run_setup }.should raise_error(SystemExit)
        end

        it "should set a central log destination with --centrallogs" do
            @agent_app.options.stubs(:[]).with(:centrallogs).returns(true)
            Puppet.stubs(:[]).with(:server).returns("puppet.reductivelabs.com")
            Puppet::Util::Log.stubs(:newdestination).with(:syslog)

            Puppet::Util::Log.expects(:newdestination).with("puppet.reductivelabs.com")

            @agent_app.run_setup
        end

        it "should use :main, :puppetd, and :ssl" do
            Puppet.settings.expects(:use).with(:main, :puppetd, :ssl)

            @agent_app.run_setup
        end

        it "should install a remote ca location" do
            Puppet::SSL::Host.expects(:ca_location=).with(:remote)

            @agent_app.run_setup
        end

        it "should tell the report handler to use REST" do
            Puppet::Transaction::Report.expects(:terminus_class=).with(:rest)

            @agent_app.run_setup
        end

        it "should tell the catalog handler to use REST" do
            Puppet::Resource::Catalog.expects(:terminus_class=).with(:rest)

            @agent_app.run_setup
        end

        it "should tell the catalog handler to use cache" do
            Puppet::Resource::Catalog.expects(:cache_class=).with(:yaml)

            @agent_app.run_setup
        end

        it "should tell the facts to use facter" do
            Puppet::Node::Facts.expects(:terminus_class=).with(:facter)

            @agent_app.run_setup
        end

        it "should create an agent" do
            Puppet::Agent.stubs(:new).with(Puppet::Configurer)

            @agent_app.run_setup
        end

        [:enable, :disable].each do |action|
            it "should delegate to enable_disable_client if we #{action} the agent" do
                @agent_app.options.stubs(:[]).with(action).returns(true)
                @agent_app.expects(:enable_disable_client).with(@agent)

                @agent_app.run_setup
            end
        end

        describe "when enabling or disabling agent" do
            [:enable, :disable].each do |action|
                it "should call client.#{action}" do
                    @agent_app.stubs(:exit)
                    @agent_app.options.stubs(:[]).with(action).returns(true)

                    @agent.expects(action)

                    @agent_app.enable_disable_client(@agent)
                end
            end

            it "should finally exit" do
                lambda { @agent_app.enable_disable_client(@agent) }.should raise_error(SystemExit)
            end
        end

        it "should inform the daemon about our agent if :client is set to 'true'" do
            @agent_app.options.expects(:[]).with(:client).returns true
            @daemon.expects(:agent=).with(@agent)
            @agent_app.run_setup
        end

        it "should not inform the daemon about our agent if :client is set to 'false'" do
            @agent_app.options[:client] = false
            @daemon.expects(:agent=).never
            @agent_app.run_setup
        end

        it "should daemonize if needed" do
            Puppet.stubs(:[]).with(:daemonize).returns(true)

            @daemon.expects(:daemonize)

            @agent_app.run_setup
        end

        it "should wait for a certificate" do
            @agent_app.options.stubs(:[]).with(:waitforcert).returns(123)
            @host.expects(:wait_for_cert).with(123)

            @agent_app.run_setup
        end

        it "should setup listen if told to and not onetime" do
            Puppet.stubs(:[]).with(:listen).returns(true)
            @agent_app.options.stubs(:[]).with(:onetime).returns(false)

            @agent_app.expects(:setup_listen)

            @agent_app.run_setup
        end

        describe "when setting up listen" do
            before :each do
                Puppet.stubs(:[]).with(:authconfig).returns('auth')
                FileTest.stubs(:exists?).with('auth').returns(true)
                File.stubs(:exist?).returns(true)
                @agent_app.options.stubs(:[]).with(:serve).returns([])
                @agent_app.stubs(:exit)
                @server = stub_everything 'server'
                Puppet::Network::Server.stubs(:new).returns(@server)
            end


            it "should exit if no authorization file" do
                Puppet.stubs(:err)
                FileTest.stubs(:exists?).with('auth').returns(false)

                @agent_app.expects(:exit)

                @agent_app.setup_listen
            end

            it "should create a server to listen on at least the Runner handler" do
                Puppet::Network::Server.expects(:new).with { |args| args[:xmlrpc_handlers] == [:Runner] }

                @agent_app.setup_listen
            end

            it "should create a server to listen for specific handlers" do
                @agent_app.options.stubs(:[]).with(:serve).returns([:handler])
                Puppet::Network::Server.expects(:new).with { |args| args[:xmlrpc_handlers] == [:handler] }

                @agent_app.setup_listen
            end

            it "should use puppet default port" do
                Puppet.stubs(:[]).with(:puppetport).returns(:port)

                Puppet::Network::Server.expects(:new).with { |args| args[:port] == :port }

                @agent_app.setup_listen
            end
        end
    end


    describe "when running" do
        before :each do
            @agent_app.agent = @agent
            @agent_app.daemon = @daemon
        end

        it "should dispatch to onetime if --onetime is used" do
            @agent_app.options.stubs(:[]).with(:onetime).returns(true)

            @agent_app.get_command.should == :onetime
        end

        it "should dispatch to main if --onetime is not used" do
            @agent_app.options.stubs(:[]).with(:onetime).returns(false)

            @agent_app.get_command.should == :main
        end

        describe "with --onetime" do

            before :each do
                @agent_app.options.stubs(:[]).with(:client).returns(:client)
                @agent_app.options.stubs(:[]).with(:detailed_exitcodes).returns(false)
                @agent_app.stubs(:exit).with(0)
                Puppet.stubs(:newservice)
            end

            it "should exit if no defined --client" do
                $stderr.stubs(:puts)
                @agent_app.options.stubs(:[]).with(:client).returns(nil)

                @agent_app.expects(:exit).with(43)

                @agent_app.onetime
            end

            it "should setup traps" do
                @daemon.expects(:set_signal_traps)

                @agent_app.onetime
            end

            it "should let the agent run" do
                @agent.expects(:run)

                @agent_app.onetime
            end

            it "should finish by exiting with 0 error code" do
                @agent_app.expects(:exit).with(0)

                @agent_app.onetime
            end

            describe "and --detailed-exitcodes" do
                before :each do
                    @puppetd.options.stubs(:[]).with(:detailed_exitcodes).returns(true)
                end

                it "should exit with report's computed exit status" do
                    Puppet.stubs(:[]).with(:noop).returns(false)
                    report = stub 'report', :exit_status => 666
                    @agent.stubs(:run).returns(report)
                    @puppetd.expects(:exit).with(666)

                    @puppetd.onetime
                end

                it "should always exit with 0 if --noop" do
                    Puppet.stubs(:[]).with(:noop).returns(true)
                    report = stub 'report', :exit_status => 666
                    @agent.stubs(:run).returns(report)
                    @puppetd.expects(:exit).with(0)

                    @puppetd.onetime
                end
            end
        end

        describe "without --onetime" do
            before :each do
                Puppet.stubs(:notice)
                @agent_app.options.stubs(:[]).with(:client)
            end

            it "should start our daemon" do
                @daemon.expects(:start)

                @agent_app.main
            end
        end
    end
end
