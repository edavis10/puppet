#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/file_serving/repository_helper'

class RepositoryHelperIntegrationTester
    include Puppet::FileServing::RepositoryHelper
    def model
        Puppet::FileServing::Metadata
    end
end

describe Puppet::FileServing::RepositoryHelper do
    it "should be able to recurse on a single file" do
        @path = Tempfile.new("fileset_integration")
        request = Puppet::RouteManager::Request.new(:metadata, :find, @path.path, :recurse => true)

        tester = RepositoryHelperIntegrationTester.new
        lambda { tester.path2instances(request, @path.path) }.should_not raise_error
    end
end
