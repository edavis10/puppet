#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/file_content/file_server'

describe Puppet::RouteManager::FileContent::FileServer do
    it "should be registered with the file_content router" do
        Puppet::RouteManager::Repository.repository_class(:file_content, :file_server).should equal(Puppet::RouteManager::FileContent::FileServer)
    end

    it "should be a subclass of the FileServer repository" do
        Puppet::RouteManager::FileContent::FileServer.superclass.should equal(Puppet::RouteManager::FileServer)
    end
end
