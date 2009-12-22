#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-9-23.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../spec_helper'

require 'puppet/node'

describe Puppet::Node do
    describe "when delegating router calls" do
        before do
            @name = "me"
            @node = Puppet::Node.new(@name)
        end

        it "should be able to use the exec repository" do
            Puppet::Node.router.stubs(:repository_class).returns :exec

            # Load now so we can stub
            repository = Puppet::Node.router.repository(:exec)

            repository.expects(:query).with(@name).returns "myresults"
            repository.expects(:translate).with(@name, "myresults").returns "translated_results"
            repository.expects(:create_node).with(@name, "translated_results").returns @node

            Puppet::Node.find(@name).should equal(@node)
        end

        it "should be able to use the yaml repository" do
            Puppet::Node.router.stubs(:repository_class).returns :yaml

            # Load now, before we stub the exists? method.
            repository = Puppet::Node.router.repository(:yaml)

            repository.expects(:path).with(@name).returns "/my/yaml/file"

            FileTest.expects(:exist?).with("/my/yaml/file").returns false
            Puppet::Node.find(@name).should be_nil
        end

        it "should have an ldap repository" do
            Puppet::Node.router.repository(:ldap).should_not be_nil
        end

        it "should be able to use the plain repository" do
            Puppet::Node.router.stubs(:repository_class).returns :plain

            # Load now, before we stub the exists? method.
            Puppet::Node.router.repository(:plain)

            Puppet::Node.expects(:new).with(@name).returns @node

            Puppet::Node.find(@name).should equal(@node)
        end

        describe "and using the memory repository" do
            before do
                @name = "me"
                @old_repository = Puppet::Node.router.repository_class
                @repository = Puppet::Node.router.repository(:memory)
                Puppet::Node.router.stubs(:repository).returns @repository
                @node = Puppet::Node.new(@name)
            end

            it "should find no nodes by default" do
                Puppet::Node.find(@name).should be_nil
            end

            it "should be able to find nodes that were previously saved" do
                @node.save
                Puppet::Node.find(@name).should equal(@node)
            end

            it "should replace existing saved nodes when a new node with the same name is saved" do
                @node.save
                two = Puppet::Node.new(@name)
                two.save
                Puppet::Node.find(@name).should equal(two)
            end

            it "should be able to remove previously saved nodes" do
                @node.save
                Puppet::Node.destroy(@node.name)
                Puppet::Node.find(@name).should be_nil
            end

            it "should fail when asked to destroy a node that does not exist" do
                proc { Puppet::Node.destroy(@node) }.should raise_error(ArgumentError)
            end
        end
    end
end
