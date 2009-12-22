#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/content'
require 'puppet/route_manager/file_content'
require 'puppet/route_manager/file_server'

class Puppet::RouteManager::FileContent::FileServer < Puppet::RouteManager::FileServer
    desc "Retrieve file contents using Puppet's fileserver."
end
