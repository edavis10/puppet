#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/runner/rest'

describe Puppet::Agent::Runner::Rest do
    it "should be a sublcass of Puppet::RouteManager::REST" do
        Puppet::Agent::Runner::Rest.superclass.should equal(Puppet::RouteManager::REST)
    end
end
