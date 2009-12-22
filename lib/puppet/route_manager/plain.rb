require 'puppet/route_manager/terminus'

# An empty terminus type, meant to just return empty objects.
class Puppet::RouteManager::Plain < Puppet::RouteManager::Terminus
    # Just return nothing.
    def find(request)
        router.model.new(request.key)
    end
end
