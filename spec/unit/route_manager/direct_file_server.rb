#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-24.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/route_manager/direct_file_server'

describe Puppet::RouteManager::DirectFileServer do
    before :each do
        Puppet::RouteManager::Repository.stubs(:register_repository_class)
        @model = mock 'model'
        @router = stub 'router', :name => :mystuff, :register_repository_type => nil, :model => @model
        Puppet::RouteManager::Router.stubs(:instance).returns(@router)

        @direct_file_class = Class.new(Puppet::RouteManager::DirectFileServer) do
            def self.to_s
                "Testing::Mytype"
            end
        end

        @server = @direct_file_class.new

        @uri = "file:///my/local"

        @request = Puppet::RouteManager::Request.new(:mytype, :find, @uri)
    end

    describe Puppet::RouteManager::DirectFileServer, "when finding a single file" do

        it "should return nil if the file does not exist" do
            FileTest.expects(:exists?).with("/my/local").returns false
            @server.find(@request).should be_nil
        end

        it "should return a Content instance created with the full path to the file if the file exists" do
            FileTest.expects(:exists?).with("/my/local").returns true
            @model.expects(:new).returns(:mycontent)
            @server.find(@request).should == :mycontent
        end
    end

    describe Puppet::RouteManager::DirectFileServer, "when creating the instance for a single found file" do

        before do
            @data = mock 'content'
            @data.stubs(:collect)
            FileTest.expects(:exists?).with("/my/local").returns true
        end

        it "should pass the full path to the instance" do
            @model.expects(:new).with { |key, options| key == "/my/local" }.returns(@data)
            @server.find(@request)
        end

        it "should pass the :links setting on to the created Content instance if the file exists and there is a value for :links" do
            @model.expects(:new).returns(@data)
            @data.expects(:links=).with(:manage)

            @request.stubs(:options).returns(:links => :manage)
            @server.find(@request)
        end
    end

    describe Puppet::RouteManager::DirectFileServer, "when searching for multiple files" do
        it "should return nil if the file does not exist" do
            FileTest.expects(:exists?).with("/my/local").returns false
            @server.find(@request).should be_nil
        end

        it "should use :path2instances from the repository_helper to return instances if the file exists" do
            FileTest.expects(:exists?).with("/my/local").returns true
            @server.expects(:path2instances)
            @server.search(@request)
        end

        it "should pass the original request to :path2instances" do
            FileTest.expects(:exists?).with("/my/local").returns true
            @server.expects(:path2instances).with(@request, "/my/local")
            @server.search(@request)
        end
    end
end
