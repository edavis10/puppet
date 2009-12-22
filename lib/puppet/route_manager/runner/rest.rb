require 'puppet/agent'
require 'puppet/agent/runner'
require 'puppet/route_manager/rest'

class Puppet::Agent::Runner::Rest < Puppet::RouteManager::REST
    desc "Trigger Agent runs via REST."
end
