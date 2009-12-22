#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/facts/rest'

describe Puppet::Node::Facts::Rest do
    it "should be a sublcass of Puppet::RouteManager::REST" do
        Puppet::Node::Facts::Rest.superclass.should equal(Puppet::RouteManager::REST)
    end
end
