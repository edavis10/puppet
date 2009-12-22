require 'puppet/ssl/certificate'
require 'puppet/route_manager/rest'

class Puppet::SSL::Certificate::Rest < Puppet::RouteManager::REST
    desc "Find and save certificates over HTTP via REST."

    use_server_setting(:ca_server)
    use_port_setting(:ca_port)

    def find(request)
        return nil unless result = super
        result.name = request.key unless result.name == request.key
        result
    end
end
