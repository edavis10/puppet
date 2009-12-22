require 'puppet/indirector/router'

class Puppet::Indirector::Router::Route
    attr_accessor :executable, :indirection, :repository, :cache

    def initialize(indirection)
        @indirection = indirection
    end
end
