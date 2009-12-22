require 'puppet/network/http/api'

module Puppet::Network::HTTP::API::V1
    # How we map http methods and the router name in the URI
    # to an router method.
    METHOD_MAP = {
        "GET" => {
            :plural => :search,
            :singular => :find
        },
        "PUT" => {
            :singular => :save
        },
        "DELETE" => {
            :singular => :destroy
        }
    }

    def uri2router(http_method, uri, params)
        environment, router, key = uri.split("/", 4)[1..-1] # the first field is always nil because of the leading slash

        raise ArgumentError, "The environment must be purely alphanumeric, not '%s'" % environment unless environment =~ /^\w+$/
        raise ArgumentError, "The router name must be purely alphanumeric, not '%s'" % router unless router =~ /^\w+$/

        method = router_method(http_method, router)

        params[:environment] = environment

        raise ArgumentError, "No request key specified in %s" % uri if key == "" or key.nil?

        key = URI.unescape(key)

        Puppet::RouteManager::Request.new(router, method, key, params)
    end

    def router2uri(request)
        router = request.method == :search ? request.router_name.to_s + "s" : request.router_name.to_s
        "/#{request.environment.to_s}/#{router}/#{request.escaped_key}#{request.query_string}"
    end

    def router_method(http_method, router)
        unless METHOD_MAP[http_method]
            raise ArgumentError, "No support for http method %s" % http_method
        end

        unless method = METHOD_MAP[http_method][plurality(router)]
            raise ArgumentError, "No support for plural %s operations" % http_method
        end

        return method
    end

    def plurality(router)
        # NOTE This specific hook for facts is ridiculous, but it's a *many*-line
        # fix to not need this, and our goal is to move away from the complication
        # that leads to the fix being too long.
        return :singular if router == "facts"

        result = (router =~ /s$/) ? :plural : :singular

        router.sub!(/s$/, '') if result

        result
    end
end
