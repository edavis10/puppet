#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'
require 'puppet/route_manager/memory'

require 'shared_behaviours/memory_terminus'

describe Puppet::RouteManager::Memory do
    it_should_behave_like "A Memory Terminus"

    before do
        Puppet::RouteManager::Terminus.stubs(:register_terminus_class)
        @model = mock 'model'
        @router = stub 'router', :name => :mystuff, :register_terminus_type => nil, :model => @model
        Puppet::RouteManager::Router.stubs(:instance).returns(@router)

        @memory_class = Class.new(Puppet::RouteManager::Memory) do
            def self.to_s
                "Mystuff::Testing"
            end
        end

        @searcher = @memory_class.new
        @name = "me"
        @instance = stub 'instance', :name => @name

        @request = stub 'request', :key => @name, :instance => @instance
    end
end
