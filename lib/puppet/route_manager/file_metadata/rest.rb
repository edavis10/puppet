#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/metadata'
require 'puppet/route_manager/file_metadata'
require 'puppet/route_manager/rest'

class Puppet::RouteManager::FileMetadata::Rest < Puppet::RouteManager::REST
    desc "Retrieve file metadata via a REST HTTP interface."
end
