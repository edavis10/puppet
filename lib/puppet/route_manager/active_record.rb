require 'puppet/route_manager'

class Puppet::RouteManager::ActiveRecord < Puppet::RouteManager::Repository
    class << self
        attr_accessor :ar_model
    end

    def self.use_ar_model(klass)
        self.ar_model = klass
    end

    def ar_model
        self.class.ar_model
    end

    def initialize
        Puppet::Rails.init
    end

    def find(request)
        return nil unless instance = ar_model.find_by_name(request.key)
        instance.to_puppet
    end

    def save(request)
        ar_model.from_puppet(request.instance).save
    end
end
