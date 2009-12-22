require 'puppet/route_manager/ssl_file'
require 'puppet/ssl/certificate_revocation_list'

class Puppet::SSL::CertificateRevocationList::File < Puppet::RouteManager::SslFile
    desc "Manage the global certificate revocation list."

    store_at :hostcrl
end
