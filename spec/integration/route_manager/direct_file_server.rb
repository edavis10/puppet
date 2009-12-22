#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-19.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/route_manager/file_content/file'

describe Puppet::RouteManager::DirectFileServer, " when interacting with the filesystem and the model" do
    before do
        # We just test a subclass, since it's close enough.
        @repository = Puppet::RouteManager::FileContent::File.new

        @filepath = "/path/to/my/file"
    end

    it "should return an instance of the model" do
        FileTest.expects(:exists?).with(@filepath).returns(true)

        @repository.find(@repository.router.request(:find, "file://host#{@filepath}")).should be_instance_of(Puppet::FileServing::Content)
    end

    it "should return an instance capable of returning its content" do
        FileTest.expects(:exists?).with(@filepath).returns(true)
        File.stubs(:lstat).with(@filepath).returns(stub("stat", :ftype => "file"))
        File.expects(:read).with(@filepath).returns("my content")

        instance = @repository.find(@repository.router.request(:find, "file://host#{@filepath}"))

        instance.content.should == "my content"
    end
end

describe Puppet::RouteManager::DirectFileServer, " when interacting with FileServing::Fileset and the model" do
    before do
        @repository = Puppet::RouteManager::FileContent::File.new

        @path = Tempfile.new("direct_file_server_testing")
        path = @path.path
        @path.close!
        @path = path

        Dir.mkdir(@path)
        File.open(File.join(@path, "one"), "w") { |f| f.print "one content" }
        File.open(File.join(@path, "two"), "w") { |f| f.print "two content" }

        @request = @repository.router.request(:search, "file:///%s" % @path, :recurse => true)
    end

    after do
        system("rm -rf %s" % @path)
    end

    it "should return an instance for every file in the fileset" do
        result = @repository.search(@request)
        result.should be_instance_of(Array)
        result.length.should == 3
        result.each { |r| r.should be_instance_of(Puppet::FileServing::Content) }
    end

    it "should return instances capable of returning their content" do
        @repository.search(@request).each do |instance|
            case instance.full_path
            when /one/; instance.content.should == "one content"
            when /two/; instance.content.should == "two content"
            when @path
            else
                raise "No valid key for %s" % instance.path.inspect
            end
        end
    end
end
