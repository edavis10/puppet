#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/metadata'
require 'puppet/route_manager/file_metadata'
require 'puppet/route_manager/file_server'

class Puppet::RouteManager::FileMetadata::FileServer < Puppet::RouteManager::FileServer
    desc "Retrieve file metadata using Puppet's fileserver."
end
