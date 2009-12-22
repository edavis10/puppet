require 'puppet/route_manager/ssl_file'
require 'puppet/ssl/key'

class Puppet::SSL::Key::Ca < Puppet::RouteManager::SslFile
    desc "Manage the CA's private on disk.  This terminus *only* works
        with the CA key, because that's the only key that the CA ever interacts
        with."

    store_in :privatekeydir

    store_ca_at :cakey
end
