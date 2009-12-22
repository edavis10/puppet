require 'puppet/node'
require 'puppet/route_manager/yaml'

class Puppet::Node::Yaml < Puppet::RouteManager::Yaml
    desc "Store node information as flat files, serialized using YAML,
        or deserialize stored YAML nodes."
end
