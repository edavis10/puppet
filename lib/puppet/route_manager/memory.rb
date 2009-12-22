require 'puppet/route_manager/repository'

# Manage a memory-cached list of instances.
class Puppet::RouteManager::Memory < Puppet::RouteManager::Repository
    def initialize
        @instances = {}
    end

    def destroy(request)
        raise ArgumentError.new("Could not find %s to destroy" % request.key) unless @instances.include?(request.key)
        @instances.delete(request.key)
    end

    def find(request)
        @instances[request.key]
    end

    def save(request)
        @instances[request.key] = request.instance
    end
end
