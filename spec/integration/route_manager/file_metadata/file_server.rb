#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/file_metadata/file_server'
require 'shared_behaviours/file_server_repository'

describe Puppet::RouteManager::FileMetadata::FileServer, " when finding files" do
    it_should_behave_like "Puppet::RouteManager::FileServerRepository"

    before do
        @repository = Puppet::RouteManager::FileMetadata::FileServer.new
        @test_class = Puppet::FileServing::Metadata
    end
end
