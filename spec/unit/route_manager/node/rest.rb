#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/route_manager/node/rest'

describe Puppet::Node::Rest do
    before do
        @searcher = Puppet::Node::Rest.new
    end


end
