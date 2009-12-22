#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/file_content/file'

describe Puppet::RouteManager::FileContent::File do
    it "should be registered with the file_content router" do
        Puppet::RouteManager::Repository.repository_class(:file_content, :file).should equal(Puppet::RouteManager::FileContent::File)
    end

    it "should be a subclass of the DirectFileServer repository" do
        Puppet::RouteManager::FileContent::File.superclass.should equal(Puppet::RouteManager::DirectFileServer)
    end
end
