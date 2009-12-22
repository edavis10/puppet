#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/catalog/rest'

describe Puppet::Resource::Catalog::Rest do
    it "should be a sublcass of Puppet::RouteManager::REST" do
        Puppet::Resource::Catalog::Rest.superclass.should equal(Puppet::RouteManager::REST)
    end
end
