require 'puppet/route_manager'
require 'puppet/route_manager/router'
require 'puppet/util/instance_loader'

# A simple class that can function as the base class for indirected types.
class Puppet::RouteManager::Repository
    require 'puppet/util/docs'
    extend Puppet::Util::Docs

    class << self
        include Puppet::Util::InstanceLoader

        attr_accessor :name, :repository_type
        attr_reader :abstract_repository, :router

        # Are we an abstract repository type, rather than an instance with an
        # associated router?
        def abstract_repository?
            abstract_repository
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
        # This follows the convention that our repository is named after the
        # router.
        def inherited(subclass)
            longname = subclass.to_s
            if longname =~ /#<Class/
                raise Puppet::DevError, "Repository subclasses must have associated constants"
            end
            names = longname.split("::")

            # Convert everything to a lower-case symbol, converting camelcase to underscore word separation.
            name = names.pop.sub(/^[A-Z]/) { |i| i.downcase }.gsub(/[A-Z]/) { |i| "_" + i.downcase }.intern

            subclass.name = name

            # Short-circuit the abstract types, which are those that directly subclass
            # the Repository class.
            if self == Puppet::RouteManager::Repository
                subclass.mark_as_abstract_repository
                return
            end

            # Set the repository type to be the name of the abstract repository type.
            # Yay, class/instance confusion.
            subclass.repository_type = self.name

            # Our subclass is specifically associated with an router.
            raise("Invalid name %s" % longname) unless names.length > 0
            router_name = names.pop.sub(/^[A-Z]/) { |i| i.downcase }.gsub(/[A-Z]/) { |i| "_" + i.downcase }.intern

            if router_name == "" or router_name.nil?
                raise Puppet::DevError, "Could not discern router model from class constant"
            end

            # This will throw an exception if the router instance cannot be found.
            # Do this last, because it also registers the repository type with the router,
            # which needs the above information.
            subclass.router = router_name

            # And add this instance to the instance hash.
            Puppet::RouteManager::Repository.register_repository_class(subclass)
        end

        # Mark that this instance is abstract.
        def mark_as_abstract_repository
            @abstract_repository = true
        end

        def model
            router.model
        end

        # Convert a short name to a constant.
        def name2const(name)
            name.to_s.capitalize.sub(/_(.)/) { |i| $1.upcase }
        end

        # Register a class, probably autoloaded.
        def register_repository_class(klass)
            setup_instance_loading klass.router_name
            instance_hash(klass.router_name)[klass.name] = klass
        end

        # Return a repository by name, using the autoloader.
        def repository_class(router_name, repository_type)
            setup_instance_loading router_name
            loaded_instance(router_name, repository_type)
        end

        # Return all repository classes for a given router.
        def repository_classes(router_name)
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
        if self.class.abstract_repository?
            raise Puppet::DevError, "Cannot create instances of abstract repository types"
        end
    end

    def model
        self.class.model
    end

    def name
        self.class.name
    end

    def repository_type
        self.class.repository_type
    end
end
