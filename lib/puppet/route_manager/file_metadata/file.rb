#
#  Created by Luke Kanies on 2007-10-16.
#  Copyright (c) 2007. All rights reserved.

require 'puppet/file_serving/metadata'
require 'puppet/route_manager/file_metadata'
require 'puppet/route_manager/direct_file_server'

class Puppet::RouteManager::FileMetadata::File < Puppet::RouteManager::DirectFileServer
    desc "Retrieve file metadata directly from the local filesystem."

    def find(request)
        return unless data = super
        data.collect

        return data
    end

    def search(request)
        return unless result = super

        result.each { |instance| instance.collect }

        return result
    end
end
