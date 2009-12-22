require 'puppet/ssl/certificate_request'
require 'puppet/route_manager/rest'

class Puppet::SSL::CertificateRequest::Rest < Puppet::RouteManager::REST
    desc "Find and save certificate requests over HTTP via REST."

    use_server_setting(:ca_server)
    use_port_setting(:ca_port)
end
