require 'puppet/route_manager'

# Handle routing routers.  Provides a means of declaring
# default routes and configuring them externally.
class Puppet::RouteManager::RouteCollection
    require 'puppet/route_manager/route_collection/route'

    def self.default
        unless defined?(@default)
            @default = new()
        end
        @default
    end

    def initialize
        @routes = []
    end

    def cache(router, arguments)
        route = build_route(router, arguments)

        unless route.cache
            raise ArgumentError, "You must specify ':in' to configure the cache repository"
        end
    end

    def route(router, arguments)
        route = build_route(router, arguments)

        unless route.repository
            raise ArgumentError, "You must specify ':to' to configure the default repository"
        end
    end

    def cache_repository(router)
        if route = find_route(router)
            route.cache
        end
    end

    def repository(router)
        if route = find_route(router)
            route.repository
        end
    end

    private

    def build_route(router, arguments)
        router = munge_router(router)
        arguments = munge_arguments(arguments)

        route = Route.new(router)

        configure_route(route, arguments)

        @routes << route
        route
    end

    def configure_route(route, arguments)
        arguments.each do |param, value|
            case param
            when :for; route.executable = value
            when :to; route.repository = value
            when :in; route.cache = value
            else
                raise ArgumentError, "Invalid route parameter %s" % param
            end
        end
    end

    def find_route(router)
        router = munge_router(router)

        program = Puppet[:name].to_sym

        if route = @routes.find { |r| r.router == router and r.executable == program }
            return route
        end

        return nil unless instance = Puppet::RouteManager::Indirection.instance(router)
        instance.default_route
    end

    def munge_arguments(arguments)
        arguments.inject({}) do |hash, ary|
            hash[ary[0].to_sym] = ary[1].to_sym
            hash
        end
    end

    def munge_router(router)
        router.to_sym
    end
end
