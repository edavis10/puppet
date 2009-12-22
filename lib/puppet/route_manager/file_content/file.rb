#
#  Created by Luke Kanies on 2007-10-16.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/content'
require 'puppet/route_manager/file_content'
require 'puppet/route_manager/direct_file_server'

class Puppet::RouteManager::FileContent::File < Puppet::RouteManager::DirectFileServer
    desc "Retrieve file contents from disk."
end
