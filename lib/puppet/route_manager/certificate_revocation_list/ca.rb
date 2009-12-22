require 'puppet/route_manager/ssl_file'
require 'puppet/ssl/certificate_revocation_list'

class Puppet::SSL::CertificateRevocationList::Ca < Puppet::RouteManager::SslFile
    desc "Manage the CA collection of certificate requests on disk."

    store_at :cacrl
end
