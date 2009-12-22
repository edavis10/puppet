require 'puppet/route_manager/ssl_file'
require 'puppet/ssl/certificate'

class Puppet::SSL::Certificate::File < Puppet::RouteManager::SslFile
    desc "Manage SSL certificates on disk."

    store_in :certdir
    store_ca_at :localcacert
end
