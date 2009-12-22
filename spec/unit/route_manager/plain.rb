#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'
require 'puppet/route_manager/plain'

describe Puppet::RouteManager::Plain do
    before do
        Puppet::RouteManager::Terminus.stubs(:register_terminus_class)
        @model = mock 'model'
        @router = stub 'router', :name => :mystuff, :register_terminus_type => nil, :model => @model
        Puppet::RouteManager::Router.stubs(:instance).returns(@router)

        @plain_class = Class.new(Puppet::RouteManager::Plain) do
            def self.to_s
                "Mystuff::Testing"
            end
        end

        @searcher = @plain_class.new

        @request = stub 'request', :key => "yay"
    end

    it "should return return an instance of the indirected model" do
        object = mock 'object'
        @model.expects(:new).with(@request.key).returns object
        @searcher.find(@request).should equal(object)
    end
end
