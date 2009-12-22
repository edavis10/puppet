#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/node/memory'

require 'shared_behaviours/memory_repository'

describe Puppet::Node::Memory do
    before do
        @name = "me"
        @searcher = Puppet::Node::Memory.new
        @instance = stub 'instance', :name => @name

        @request = stub 'request', :key => @name, :instance => @instance
    end

    it_should_behave_like "A Memory Repository"
end
