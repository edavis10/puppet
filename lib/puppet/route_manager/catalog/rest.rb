require 'puppet/resource/catalog'
require 'puppet/route_manager/rest'

class Puppet::Resource::Catalog::Rest < Puppet::RouteManager::REST
    desc "Find resource catalogs over HTTP via REST."
end
