# Manage routers to termini.  They are organized in terms of routers -
# - e.g., configuration, node, file, certificate -- and each router has one
# or more terminus types defined.  The router is configured via the
# +indirects+ method, which will be called by the class extending itself
# with this module.
module Puppet::RouteManager
    # LAK:FIXME We need to figure out how to handle documentation for the
    # different router types.

    require 'puppet/route_manager/router'
    require 'puppet/route_manager/terminus'
    require 'puppet/route_manager/envelope'
    require 'puppet/network/format_handler'

    # Declare that the including class indirects its methods to
    # this terminus.  The terminus name must be the name of a Puppet
    # default, not the value -- if it's the value, then it gets
    # evaluated at parse time, which is before the user has had a chance
    # to override it.
    def indirects(router, options = {})
        raise(ArgumentError, "Already handling router for %s; cannot also handle %s" % [@router.name, router]) if defined?(@router) and @router
        # populate this class with the various new methods
        extend ClassMethods
        include InstanceMethods
        include Puppet::RouteManager::Envelope
        extend Puppet::Network::FormatHandler

        # instantiate the actual Terminus for that type and this name (:ldap, w/ args :node)
        # & hook the instantiated Terminus into this class (Node: @router = terminus)
        @router = Puppet::RouteManager::Router.new(self, router,  options)
        @router
    end

    module ClassMethods   
        attr_reader :router

        def cache_class=(klass)
            router.cache_class = klass
        end

        def terminus_class=(klass)
            router.terminus_class = klass
        end
         
        # Expire any cached instance.
        def expire(*args)
            router.expire(*args)
        end
         
        def find(*args)
            router.find(*args)
        end

        def destroy(*args)
            router.destroy(*args)
        end

        def search(*args)
            router.search(*args)
        end
    end

    module InstanceMethods
        def save(*args)
            self.class.router.save self, *args
        end
    end
end
