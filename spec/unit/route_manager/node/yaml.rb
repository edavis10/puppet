#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/node'
require 'puppet/route_manager/node/yaml'

describe Puppet::Node::Yaml do
    it "should be a subclass of the Yaml repository" do
        Puppet::Node::Yaml.superclass.should equal(Puppet::RouteManager::Yaml)
    end

    it "should have documentation" do
        Puppet::Node::Yaml.doc.should_not be_nil
    end

    it "should be registered with the configuration store router" do
        router = Puppet::RouteManager::Router.instance(:node)
        Puppet::Node::Yaml.router.should equal(router)
    end

    it "should have its name set to :node" do
        Puppet::Node::Yaml.name.should == :yaml
    end
end
