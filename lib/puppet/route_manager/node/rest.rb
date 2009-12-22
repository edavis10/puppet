require 'puppet/node'
require 'puppet/route_manager/rest'

class Puppet::Node::Rest < Puppet::RouteManager::REST
    desc "This will eventually be a REST-based mechanism for finding nodes.  It is currently non-functional."
    # TODO/FIXME
end
