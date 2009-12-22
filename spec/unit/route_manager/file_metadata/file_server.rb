#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/file_metadata/file_server'

describe Puppet::RouteManager::FileMetadata::FileServer do
    it "should be registered with the file_metadata router" do
        Puppet::RouteManager::Repository.repository_class(:file_metadata, :file_server).should equal(Puppet::RouteManager::FileMetadata::FileServer)
    end

    it "should be a subclass of the FileServer repository" do
        Puppet::RouteManager::FileMetadata::FileServer.superclass.should equal(Puppet::RouteManager::FileServer)
    end
end
