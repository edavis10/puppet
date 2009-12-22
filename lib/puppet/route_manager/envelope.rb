require 'puppet/route_manager'

# Provide any attributes or functionality needed for indirected
# instances.
module Puppet::RouteManager::Envelope
    attr_accessor :expiration

    def expired?
        return false unless expiration
        return false if expiration >= Time.now
        return true
    end
end
