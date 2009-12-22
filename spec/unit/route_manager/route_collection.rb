#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'
require 'puppet/indirector/router'

describe Puppet::RouteManager::RouteCollection do
    it "should support declaring routes" do
        Puppet::RouteManager::RouteCollection.new.should respond_to(:route)
    end

    it "should have a default, global router" do
        Puppet::RouteManager::RouteCollection.default.should be_instance_of(Puppet::RouteManager::RouteCollection)
    end

    it "should always use the same default router" do
        Puppet::RouteManager::RouteCollection.default.should equal(Puppet::RouteManager::RouteCollection.default)
    end

    it "should be able to return a repository for a given router" do
        Puppet::RouteManager::RouteCollection.new.should respond_to(:repository)
    end

    it "should be able to return a cache for a given router" do
        Puppet::RouteManager::RouteCollection.new.should respond_to(:cache)
    end

    describe "when routing" do
        before do
            @route_collection = Puppet::RouteManager::RouteCollection.new
            Puppet.settings.stubs(:[]).with(:name).returns "myprog"
        end

        it "should be able to return the repository for a previously routed router" do
            @route_collection.route(:catalog, :for => "myprog", :to => :myrepository)

            @route_collection.repository(:catalog).should == :myrepository
        end

        it "should be able to return the cache repository for a previously routed router" do
            @route_collection.cache(:catalog, :for => "myprog", :in => :mycache)

            @route_collection.cache_repository(:catalog).should == :mycache
        end

        it "should choose the appopriate executable routes based on the executable name" do
            Puppet.settings.expects(:[]).with(:name).returns "yayprog"

            @route_collection.route(:catalog, :for => "yayprog", :to => :yayrepository)
            @route_collection.route(:catalog, :for => "otherprog", :to => :othercache)

            @route_collection.repository(:catalog).should == :yayrepository
        end

        it "should support executables specified as symbols" do
            @route_collection.route(:catalog, :for => :myprog, :to => :myrepository)

            @route_collection.repository(:catalog).should == :myrepository
        end

        it "should support router names specified as symbols or strings" do
            @route_collection.route("catalog", :for => :myprog, :to => :myrepository)

            @route_collection.repository("catalog").should == :myrepository
        end

        it "should use the router's default route if no route is matched" do
            route = mock 'route', :repository => :foo

            router = mock 'router', :default_route => route
            Puppet::RouteManager::RouteCollection.expects(:instance).returns router

            @route_collection.repository("catalog").should == :foo
        end

        it "should return nil if no route is matched and no default route is found" do
            router = mock 'router', :default_route => nil
            Puppet::RouteManager::RouteCollection.expects(:instance).returns router

            @route_collection.repository("catalog").should be_nil
        end

        it "should return nil if no router can be found to route" do
            Puppet::RouteManager::RouteCollection.expects(:instance).returns nil

            @route_collection.repository("catalog").should be_nil
        end
    end
end
