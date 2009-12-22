require 'puppet/ssl/certificate_revocation_list'
require 'puppet/route_manager/rest'

class Puppet::SSL::CertificateRevocationList::Rest < Puppet::RouteManager::REST
    desc "Find and save certificate revocation lists over HTTP via REST."

    use_server_setting(:ca_server)
    use_port_setting(:ca_port)
end
