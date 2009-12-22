#
#  Created by Luke Kanies on 2007-10-24.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/repository_helper'
require 'puppet/route_manager/repository'

class Puppet::RouteManager::DirectFileServer < Puppet::RouteManager::Repository

    include Puppet::FileServing::RepositoryHelper

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
