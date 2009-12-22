#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/resource/catalog'
require 'puppet/route_manager/catalog/yaml'

describe Puppet::Resource::Catalog::Yaml do
    it "should be a subclass of the Yaml terminus" do
        Puppet::Resource::Catalog::Yaml.superclass.should equal(Puppet::RouteManager::Yaml)
    end

    it "should have documentation" do
        Puppet::Resource::Catalog::Yaml.doc.should_not be_nil
    end

    it "should be registered with the catalog store router" do
        router = Puppet::RouteManager::Router.instance(:catalog)
        Puppet::Resource::Catalog::Yaml.router.should equal(router)
    end

    it "should have its name set to :yaml" do
        Puppet::Resource::Catalog::Yaml.name.should == :yaml
    end
end
