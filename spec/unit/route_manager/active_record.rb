#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/route_manager/active_record'

describe Puppet::RouteManager::ActiveRecord do
    before do
        Puppet::Rails.stubs(:init)

        Puppet::RouteManager::Repository.stubs(:register_repository_class)
        @model = mock 'model'
        @router = stub 'router', :name => :mystuff, :register_repository_type => nil, :model => @model
        Puppet::RouteManager::Router.stubs(:instance).returns(@router)

        @active_record_class = Class.new(Puppet::RouteManager::ActiveRecord) do
            def self.to_s
                "Mystuff::Testing"
            end
        end

        @ar_model = mock 'ar_model'

        @active_record_class.use_ar_model @ar_model
        @repository = @active_record_class.new

        @name = "me"
        @instance = stub 'instance', :name => @name

        @request = stub 'request', :key => @name, :instance => @instance
    end

    it "should allow declaration of an ActiveRecord model to use" do
        @active_record_class.use_ar_model "foo"
        @active_record_class.ar_model.should == "foo"
    end

    describe "when initializing" do
        it "should init Rails" do
            Puppet::Rails.expects(:init)
            @active_record_class.new
        end
    end

    describe "when finding an instance" do
        it "should use the ActiveRecord model to find the instance" do
            @ar_model.expects(:find_by_name).with(@name)

            @repository.find(@request)
        end

        it "should return nil if no instance is found" do
            @ar_model.expects(:find_by_name).with(@name).returns nil
            @repository.find(@request).should be_nil
        end

        it "should convert the instance to a Puppet object if it is found" do
            instance = mock 'rails_instance'
            instance.expects(:to_puppet).returns "mypuppet"

            @ar_model.expects(:find_by_name).with(@name).returns instance
            @repository.find(@request).should == "mypuppet"
        end
    end

    describe "when saving an instance" do
        it "should use the ActiveRecord model to convert the instance into a Rails object and then save that rails object" do
            rails_object = mock 'rails_object'
            @ar_model.expects(:from_puppet).with(@instance).returns rails_object

            rails_object.expects(:save)

            @repository.save(@request)
        end
    end
end
