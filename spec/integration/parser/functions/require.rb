#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

describe "the require function" do

    before :each do
        @parser = Puppet::Parser::Parser.new :Code => ""
        @node = Puppet::Node.new("mynode")
        @compiler = Puppet::Parser::Compiler.new(@node, @parser)

        @compiler.send(:evaluate_main)
        @compiler.catalog.client_version = "0.25"
        @scope = @compiler.topscope
        # preload our functions
        Puppet::Parser::Functions.function(:include)
        Puppet::Parser::Functions.function(:require)
    end

    it "should add a relationship between the 'required' class and our class" do
        @parser.newclass("requiredclass")

        @scope.function_require("requiredclass")
        @scope.resource["require"].should_not be_nil
        ref = @scope.resource["require"]
        ref.type.should == "Class"
        ref.title.should == "requiredclass"
    end
end

describe "the include function" do
    require 'puppet_spec/files'
    include PuppetSpec::Files

    before :each do
        @real_dir = Dir.getwd
        @temp_dir = tmpfile('include_function_integration_test')
        Dir.mkdir @temp_dir
        Dir.chdir @temp_dir
        @parser = Puppet::Parser::Parser.new :Code => ""
        @node = Puppet::Node.new("mynode")
        @compiler = Puppet::Parser::Compiler.new(@node, @parser)
        @compiler.send(:evaluate_main)
        @scope = @compiler.topscope
        # preload our functions
        Puppet::Parser::Functions.function(:include)
        Puppet::Parser::Functions.function(:require)
    end

    after :each do
        Dir.chdir @real_dir
        Dir.rmdir @temp_dir
    end

    def with_file(filename,contents)
        path = File.join(@temp_dir,filename)
        File.open(path, "w") { |f|f.puts contents }
        yield
        File.delete(path)
    end

    it "should add a relationship between the 'included' class and our class" do
        with_file('includedclass',"class includedclass {}") {
            @scope.function_include("includedclass")
            }
        @compiler.catalog.edge?(@scope.resource,@compiler.findresource(:class,"includedclass")).should be_true
    end

end
