#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/content'
require 'puppet/route_manager/file_content'
require 'puppet/route_manager/rest'

class Puppet::RouteManager::FileContent::Rest < Puppet::RouteManager::REST
    desc "Retrieve file contents via a REST HTTP interface."
end
