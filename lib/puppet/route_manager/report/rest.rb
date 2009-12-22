require 'puppet/route_manager/rest'

class Puppet::Transaction::Report::Rest < Puppet::RouteManager::REST
    desc "Get server report over HTTP via REST."
    use_server_setting(:report_server)
    use_port_setting(:report_port)
end
