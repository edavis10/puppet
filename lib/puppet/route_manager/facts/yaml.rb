require 'puppet/node/facts'
require 'puppet/route_manager/yaml'

class Puppet::Node::Facts::Yaml < Puppet::RouteManager::Yaml
    desc "Store client facts as flat files, serialized using YAML, or
        return deserialized facts from disk."
end
