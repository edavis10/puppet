require 'puppet/route_manager/repository'

# Do nothing, requiring that the back-end repository do all
# of the work.
class Puppet::RouteManager::Code < Puppet::RouteManager::Repository
end
