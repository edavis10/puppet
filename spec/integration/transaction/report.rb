#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2008-4-8.
#  Copyright (c) 2008. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

describe Puppet::Transaction::Report do
    describe "when using the route_manager" do
        after do
            Puppet::Util::Cacher.expire
            Puppet.settings.stubs(:use)
        end

        it "should be able to delegate to the :processor repository" do
            Puppet::Transaction::Report.router.stubs(:repository_class).returns :processor

            repository = Puppet::Transaction::Report.router.repository(:processor)

            Facter.stubs(:value).returns "host.domain.com"

            report = Puppet::Transaction::Report.new

            repository.expects(:process).with(report)

            report.save
        end
    end
end
