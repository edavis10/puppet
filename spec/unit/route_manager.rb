#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

require 'puppet/defaults'
require 'puppet/route_manager'

describe Puppet::RouteManager, " when available to a model" do
    before do
        @thingie = Class.new do
            extend Puppet::RouteManager
        end
    end

    it "should provide a way for the model to register an router under a name" do
        @thingie.should respond_to(:routes)
    end
end

describe Puppet::RouteManager, "when registering an router" do
    before do
        @thingie = Class.new do
            extend Puppet::RouteManager
            attr_reader :name
            def initialize(name)
                @name = name
            end
        end
    end

    it "should require a name when registering a model" do
        Proc.new {@thingie.send(:routes) }.should raise_error(ArgumentError)
    end

    it "should create an router instance to manage each indirecting model" do
        @router = @thingie.routes(:test)
        @router.should be_instance_of(Puppet::RouteManager::Router)
    end

    it "should not allow a model to register under multiple names" do
        # Keep track of the router instance so we can delete it on cleanup
        @router = @thingie.routes :first
        Proc.new { @thingie.routes :second }.should raise_error(ArgumentError)
    end

    it "should make the router available via an accessor" do
        @router = @thingie.routes :first
        @thingie.router.should equal(@router)
    end

    it "should pass any provided options to the router during initialization" do
        klass = mock 'repository class'
        Puppet::RouteManager::Router.expects(:new).with(@thingie, :first, {:some => :options})
        @router = @thingie.routes :first, :some => :options
    end

    it "should extend the class with the Format Handler" do
        @router = @thingie.routes :first
        @thingie.metaclass.ancestors.should be_include(Puppet::Network::FormatHandler)
    end

    after do
        @router.delete if @router
    end
end

describe "Delegated Router Method", :shared => true do
    it "should delegate to the router" do
        @router.expects(@method)
        @thingie.send(@method, "me")
    end

    it "should pass all of the passed arguments directly to the router instance" do
        @router.expects(@method).with("me", :one => :two)
        @thingie.send(@method, "me", :one => :two)
    end

    it "should return the results of the delegation as its result" do
        request = mock 'request'
        @router.expects(@method).returns "yay"
        @thingie.send(@method, "me").should == "yay"
    end
end

describe Puppet::RouteManager, "when redirecting a model" do
    before do
        @thingie = Class.new do
            extend Puppet::RouteManager
            attr_reader :name
            def initialize(name)
                @name = name
            end
        end
        @router = @thingie.send(:routes, :test)
    end

    it "should include the Envelope module in the model" do
        @thingie.ancestors.should be_include(Puppet::RouteManager::Envelope)
    end

    describe "when finding instances via the model" do
        before { @method = :find }
        it_should_behave_like "Delegated Router Method"
    end

    describe "when destroying instances via the model" do
        before { @method = :destroy }
        it_should_behave_like "Delegated Router Method"
    end

    describe "when searching for instances via the model" do
        before { @method = :search }
        it_should_behave_like "Delegated Router Method"
    end

    describe "when expiring instances via the model" do
        before { @method = :expire }
        it_should_behave_like "Delegated Router Method"
    end

    # This is an instance method, so it behaves a bit differently.
    describe "when saving instances via the model" do
        before do
            @instance = @thingie.new("me")
        end

        it "should delegate to the router" do
            @router.expects(:save)
            @instance.save
        end

        it "should pass the instance and all arguments to the router's :save method" do
            @router.expects(:save).with(@instance, :one => :two)
            @instance.save :one => :two
        end

        it "should return the results of the delegation as its result" do
            request = mock 'request'
            @router.expects(:save).returns "yay"
            @instance.save.should == "yay"
        end
    end

    it "should give the model the ability to set the router repository class" do
        @router.expects(:repository_class=).with(:myterm)
        @thingie.repository_class = :myterm
    end

    it "should give the model the ability to set the router cache class" do
        @router.expects(:cache_class=).with(:mycache)
        @thingie.cache_class = :mycache
    end

    after do
        @router.delete
    end
end
