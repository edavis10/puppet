#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/catalog/queue'

describe Puppet::Resource::Catalog::Queue do
    it 'should be a subclass of the Queue repository' do
        Puppet::Resource::Catalog::Queue.superclass.should equal(Puppet::RouteManager::Queue)
    end

    it 'should be registered with the catalog store router' do
        router = Puppet::RouteManager::Router.instance(:catalog)
        Puppet::Resource::Catalog::Queue.router.should equal(router)
    end

    it 'shall be dubbed ":queue"' do
        Puppet::Resource::Catalog::Queue.name.should == :queue
    end
end
