#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/route_collection/route'

describe Puppet::RouteManager::RouteCollection::Route do
    it "should require an router name" do
        lambda { Puppet::RouteManager::RouteCollection::Route.new }.should raise_error(ArgumentError)
    end

    it "should support a executable name" do
        route = Puppet::RouteManager::RouteCollection::Route.new(:catalog)
        route.executable = :puppetd
        route.executable.should == :puppetd
    end

    it "should support a repository" do
        route = Puppet::RouteManager::RouteCollection::Route.new(:catalog)
        route.repository = :compiler
        route.repository.should == :compiler
    end

    it "should support a cache repository" do
        route = Puppet::RouteManager::RouteCollection::Route.new(:catalog)
        route.cache = :compiler
        route.cache.should == :compiler
    end
end
