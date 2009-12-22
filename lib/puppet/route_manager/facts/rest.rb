require 'puppet/node/facts'
require 'puppet/route_manager/rest'

class Puppet::Node::Facts::Rest < Puppet::RouteManager::REST
    desc "Find and save facts about nodes over HTTP via REST."
end
