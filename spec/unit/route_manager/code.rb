#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'
require 'puppet/route_manager/code'

describe Puppet::RouteManager::Code do
    before do
        Puppet::RouteManager::Repository.stubs(:register_repository_class)
        @model = mock 'model'
        @router = stub 'router', :name => :mystuff, :register_repository_type => nil, :model => @model
        Puppet::RouteManager::Router.stubs(:instance).returns(@router)

        @code_class = Class.new(Puppet::RouteManager::Code) do
            def self.to_s
                "Mystuff::Testing"
            end
        end

        @searcher = @code_class.new
    end

    it "should not have a find() method defined" do
        @searcher.should_not respond_to(:find)
    end

    it "should not have a save() method defined" do
        @searcher.should_not respond_to(:save)
    end

    it "should not have a destroy() method defined" do
        @searcher.should_not respond_to(:destroy)
    end
end
