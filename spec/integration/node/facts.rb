#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2008-4-8.
#  Copyright (c) 2008. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

describe Puppet::Node::Facts do
    describe "when using the route_manager" do
        after { Puppet::Util::Cacher.expire }

        it "should expire any cached node instances when it is saved" do
            Puppet::Node::Facts.router.stubs(:repository_class).returns :yaml

            Puppet::Node::Facts.router.repository(:yaml).should equal(Puppet::Node::Facts.router.repository(:yaml))
            repository = Puppet::Node::Facts.router.repository(:yaml)
            repository.stubs :save

            Puppet::Node.expects(:expire).with("me")

            facts = Puppet::Node::Facts.new("me")
            facts.save
        end

        it "should be able to delegate to the :yaml repository" do
            Puppet::Node::Facts.router.stubs(:repository_class).returns :yaml

            # Load now, before we stub the exists? method.
            repository = Puppet::Node::Facts.router.repository(:yaml)

            repository.expects(:path).with("me").returns "/my/yaml/file"
            FileTest.expects(:exist?).with("/my/yaml/file").returns false

            Puppet::Node::Facts.find("me").should be_nil
        end

        it "should be able to delegate to the :facter repository" do
            Puppet::Node::Facts.router.stubs(:repository_class).returns :facter

            Facter.expects(:to_hash).returns "facter_hash"
            facts = Puppet::Node::Facts.new("me")
            Puppet::Node::Facts.expects(:new).with("me", "facter_hash").returns facts

            Puppet::Node::Facts.find("me").should equal(facts)
        end
    end
end
