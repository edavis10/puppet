require 'puppet/route_manager/terminus'

# Do nothing, requiring that the back-end terminus do all
# of the work.
class Puppet::RouteManager::Code < Puppet::RouteManager::Terminus
end
