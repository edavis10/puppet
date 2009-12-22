#
#  Created by Luke Kanies on 2007-10-24.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/terminus_helper'
require 'puppet/route_manager/terminus'

class Puppet::RouteManager::DirectFileServer < Puppet::RouteManager::Terminus

    include Puppet::FileServing::TerminusHelper

    def find(request)
        return nil unless FileTest.exists?(request.key)
        instance = model.new(request.key)
        instance.links = request.options[:links] if request.options[:links]
        return instance
    end

    def search(request)
        return nil unless FileTest.exists?(request.key)
        path2instances(request, request.key)
    end
end
