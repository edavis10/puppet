#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/node/ldap'

describe Puppet::Node::Ldap do
    it "should use a restrictive filter when searching for nodes in a class" do
        ldap = Puppet::Node.router.terminus(:ldap)
        Puppet::Node.router.stubs(:terminus).returns ldap
        ldap.expects(:ldapsearch).with("(&(objectclass=puppetClient)(puppetclass=foo))")

        Puppet::Node.search "eh", :class => "foo"
    end
end
