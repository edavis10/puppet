require 'puppet/rails/host'
require 'puppet/route_manager/active_record'
require 'puppet/node'

class Puppet::Node::ActiveRecord < Puppet::RouteManager::ActiveRecord
    use_ar_model Puppet::Rails::Host

    def find(request)
        node = super
        node.fact_merge
        node
    end
end
