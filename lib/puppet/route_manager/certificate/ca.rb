require 'puppet/route_manager/ssl_file'
require 'puppet/ssl/certificate'

class Puppet::SSL::Certificate::Ca < Puppet::RouteManager::SslFile
    desc "Manage the CA collection of signed SSL certificates on disk."

    store_in :signeddir
    store_ca_at :cacert
end
