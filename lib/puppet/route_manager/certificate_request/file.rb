require 'puppet/route_manager/ssl_file'
require 'puppet/ssl/certificate_request'

class Puppet::SSL::CertificateRequest::File < Puppet::RouteManager::SslFile
    desc "Manage the collection of certificate requests on disk."

    store_in :requestdir
end
