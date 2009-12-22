require 'puppet/route_manager/repository'

# An empty repository type, meant to just return empty objects.
class Puppet::RouteManager::Plain < Puppet::RouteManager::Repository
    # Just return nothing.
    def find(request)
        router.model.new(request.key)
    end
end
