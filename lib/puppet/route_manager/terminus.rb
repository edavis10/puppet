require 'puppet/route_manager'
require 'puppet/route_manager/router'
require 'puppet/util/instance_loader'

# A simple class that can function as the base class for indirected types.
class Puppet::RouteManager::Terminus
    require 'puppet/util/docs'
    extend Puppet::Util::Docs

    class << self
        include Puppet::Util::InstanceLoader

        attr_accessor :name, :terminus_type
        attr_reader :abstract_terminus, :router

        # Are we an abstract terminus type, rather than an instance with an
        # associated router?
        def abstract_terminus?
            abstract_terminus
        end

        # Convert a constant to a short name.
        def const2name(const)
            const.sub(/^[A-Z]/) { |i| i.downcase }.gsub(/[A-Z]/) { |i| "_" + i.downcase }.intern
        end

        # Look up the router if we were only provided a name.
        def router=(name)
            if name.is_a?(Puppet::RouteManager::Router)
                @router = name
            elsif ind = Puppet::RouteManager::Router.instance(name)
                @router = ind
            else
                raise ArgumentError, "Could not find router instance %s for %s" % [name, self.name]
            end
        end

        def router_name
            @router.name
        end

        # Register our subclass with the appropriate router.
        # This follows the convention that our terminus is named after the
        # router.
        def inherited(subclass)
            longname = subclass.to_s
            if longname =~ /#<Class/
                raise Puppet::DevError, "Terminus subclasses must have associated constants"
            end
            names = longname.split("::")

            # Convert everything to a lower-case symbol, converting camelcase to underscore word separation.
            name = names.pop.sub(/^[A-Z]/) { |i| i.downcase }.gsub(/[A-Z]/) { |i| "_" + i.downcase }.intern

            subclass.name = name

            # Short-circuit the abstract types, which are those that directly subclass
            # the Terminus class.
            if self == Puppet::RouteManager::Terminus
                subclass.mark_as_abstract_terminus
                return
            end

            # Set the terminus type to be the name of the abstract terminus type.
            # Yay, class/instance confusion.
            subclass.terminus_type = self.name

            # Our subclass is specifically associated with an router.
            raise("Invalid name %s" % longname) unless names.length > 0
            router_name = names.pop.sub(/^[A-Z]/) { |i| i.downcase }.gsub(/[A-Z]/) { |i| "_" + i.downcase }.intern

            if router_name == "" or router_name.nil?
                raise Puppet::DevError, "Could not discern router model from class constant"
            end

            # This will throw an exception if the router instance cannot be found.
            # Do this last, because it also registers the terminus type with the router,
            # which needs the above information.
            subclass.router = router_name

            # And add this instance to the instance hash.
            Puppet::RouteManager::Terminus.register_terminus_class(subclass)
        end

        # Mark that this instance is abstract.
        def mark_as_abstract_terminus
            @abstract_terminus = true
        end

        def model
            router.model
        end

        # Convert a short name to a constant.
        def name2const(name)
            name.to_s.capitalize.sub(/_(.)/) { |i| $1.upcase }
        end

        # Register a class, probably autoloaded.
        def register_terminus_class(klass)
            setup_instance_loading klass.router_name
            instance_hash(klass.router_name)[klass.name] = klass
        end

        # Return a terminus by name, using the autoloader.
        def terminus_class(router_name, terminus_type)
            setup_instance_loading router_name
            loaded_instance(router_name, terminus_type)
        end

        # Return all terminus classes for a given router.
        def terminus_classes(router_name)
            setup_instance_loading router_name

            # Load them all.
            instance_loader(router_name).loadall

            # And return the list of names.
            loaded_instances(router_name)
        end

        private

        def setup_instance_loading(type)
            unless instance_loading?(type)
                instance_load type, "puppet/route_manager/%s" % type
            end
        end
    end

    def router
        self.class.router
    end

    def initialize
        if self.class.abstract_terminus?
            raise Puppet::DevError, "Cannot create instances of abstract terminus types"
        end
    end

    def model
        self.class.model
    end

    def name
        self.class.name
    end

    def terminus_type
        self.class.terminus_type
    end
end
