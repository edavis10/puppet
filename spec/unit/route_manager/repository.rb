#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'
require 'puppet/defaults'
require 'puppet/route_manager'
require 'puppet/route_manager/file'

describe Puppet::RouteManager::Repository do
    before :each do
        Puppet::RouteManager::Repository.stubs(:register_repository_class)
        @router = stub 'router', :name => :my_stuff, :register_repository_type => nil
        Puppet::RouteManager::Router.stubs(:instance).with(:my_stuff).returns(@router)
        @abstract_repository = Class.new(Puppet::RouteManager::Repository) do
            def self.to_s
                "Testing::Abstract"
            end
        end
        @repository_class = Class.new(@abstract_repository) do
            def self.to_s
                "MyStuff::TermType"
            end
        end
        @repository = @repository_class.new
    end

    describe Puppet::RouteManager::Repository do

        it "should provide a method for setting repository class documentation" do
            @repository_class.should respond_to(:desc)
        end

        it "should support a class-level name attribute" do
            @repository_class.should respond_to(:name)
        end

        it "should support a class-level router attribute" do
            @repository_class.should respond_to(:router)
        end

        it "should support a class-level repository-type attribute" do
            @repository_class.should respond_to(:repository_type)
        end

        it "should support a class-level model attribute" do
            @repository_class.should respond_to(:model)
        end

        it "should accept router instances as its router" do
            router = stub 'router', :is_a? => true, :register_repository_type => nil
            proc { @repository_class.router = router }.should_not raise_error
            @repository_class.router.should equal(router)
        end

        it "should look up router instances when only a name has been provided" do
            router = mock 'router'
            Puppet::RouteManager::Router.expects(:instance).with(:myind).returns(router)
            @repository_class.router = :myind
            @repository_class.router.should equal(router)
        end

        it "should fail when provided a name that does not resolve to an router" do
            Puppet::RouteManager::Router.expects(:instance).with(:myind).returns(nil)
            proc { @repository_class.router = :myind }.should raise_error(ArgumentError)

            # It shouldn't overwrite our existing one (or, more normally, it shouldn't set
            # anything).
            @repository_class.router.should equal(@router)
        end
    end

    describe Puppet::RouteManager::Repository, " when creating repository classes" do
        it "should associate the subclass with an router based on the subclass constant" do
            @repository.router.should equal(@router)
        end

        it "should set the subclass's type to the abstract repository name" do
            @repository.repository_type.should == :abstract
        end

        it "should set the subclass's name to the router name" do
            @repository.name.should == :term_type
        end

        it "should set the subclass's model to the router model" do
            @router.expects(:model).returns :yay
            @repository.model.should == :yay
        end
    end

    describe Puppet::RouteManager::Repository, " when a repository instance" do

        it "should return the class's name as its name" do
            @repository.name.should == :term_type
        end

        it "should return the class's router as its router" do
            @repository.router.should equal(@router)
        end

        it "should set the instances's type to the abstract repository type's name" do
            @repository.repository_type.should == :abstract
        end

        it "should set the instances's model to the router's model" do
            @router.expects(:model).returns :yay
            @repository.model.should == :yay
        end
    end
end

# LAK: This could reasonably be in the Router instances, too.  It doesn't make
# a whole heckuva lot of difference, except that with the instance loading in
# the Repository base class, we have to have a check to see if we're already
# instance-loading a given repository class type.
describe Puppet::RouteManager::Repository, " when managing repository classes" do
    it "should provide a method for registering repository classes" do
        Puppet::RouteManager::Repository.should respond_to(:register_repository_class)
    end

    it "should provide a method for returning repository classes by name and type" do
        repository = stub 'repository_type', :name => :abstract, :router_name => :whatever
        Puppet::RouteManager::Repository.register_repository_class(repository)
        Puppet::RouteManager::Repository.repository_class(:whatever, :abstract).should equal(repository)
    end

    it "should set up autoloading for any repository class types requested" do
        Puppet::RouteManager::Repository.expects(:instance_load).with(:test2, "puppet/route_manager/test2")
        Puppet::RouteManager::Repository.repository_class(:test2, :whatever)
    end

    it "should load repository classes that are not found" do
        # Set up instance loading; it would normally happen automatically
        Puppet::RouteManager::Repository.instance_load :test1, "puppet/route_manager/test1"

        Puppet::RouteManager::Repository.instance_loader(:test1).expects(:load).with(:yay)
        Puppet::RouteManager::Repository.repository_class(:test1, :yay)
    end

    it "should fail when no router can be found" do
        Puppet::RouteManager::Router.expects(:instance).with(:my_router).returns(nil)

        @abstract_repository = Class.new(Puppet::RouteManager::Repository) do
            def self.to_s
                "Abstract"
            end
        end
        proc {
            @repository = Class.new(@abstract_repository) do
                def self.to_s
                    "MyRouter::TestType"
                end
            end
        }.should raise_error(ArgumentError)
    end

    it "should register the repository class with the repository base class" do
        Puppet::RouteManager::Repository.expects(:register_repository_class).with do |type|
            type.router_name == :my_router and type.name == :test_repository
        end
        @router = stub 'router', :name => :my_router, :register_repository_type => nil
        Puppet::RouteManager::Router.expects(:instance).with(:my_router).returns(@router)

        @abstract_repository = Class.new(Puppet::RouteManager::Repository) do
            def self.to_s
                "Abstract"
            end
        end

        @repository = Class.new(@abstract_repository) do
            def self.to_s
                "MyRouter::TestRepository"
            end
        end
    end
end

describe Puppet::RouteManager::Repository, " when parsing class constants for router and repository names" do
    before do
        @subclass = mock 'subclass'
        @subclass.stubs(:to_s).returns("TestInd::OneTwo")
        @subclass.stubs(:mark_as_abstract_repository)
        Puppet::RouteManager::Repository.stubs(:register_repository_class)
    end

    it "should fail when anonymous classes are used" do
        proc { Puppet::RouteManager::Repository.inherited(Class.new) }.should raise_error(Puppet::DevError)
    end

    it "should use the last term in the constant for the repository class name" do
        @subclass.expects(:name=).with(:one_two)
        @subclass.stubs(:router=)
        Puppet::RouteManager::Repository.inherited(@subclass)
    end

    it "should convert the repository name to a downcased symbol" do
        @subclass.expects(:name=).with(:one_two)
        @subclass.stubs(:router=)
        Puppet::RouteManager::Repository.inherited(@subclass)
    end

    it "should use the second to last term in the constant for the router name" do
        @subclass.expects(:router=).with(:test_ind)
        @subclass.stubs(:name=)
        @subclass.stubs(:repository_type=)
        Puppet::RouteManager::File.inherited(@subclass)
    end

    it "should convert the router name to a downcased symbol" do
        @subclass.expects(:router=).with(:test_ind)
        @subclass.stubs(:name=)
        @subclass.stubs(:repository_type=)
        Puppet::RouteManager::File.inherited(@subclass)
    end

    it "should convert camel case to lower case with underscores as word separators" do
        @subclass.expects(:name=).with(:one_two)
        @subclass.stubs(:router=)

        Puppet::RouteManager::Repository.inherited(@subclass)
    end
end

describe Puppet::RouteManager::Repository, " when creating repository class types" do
    before do
        Puppet::RouteManager::Repository.stubs(:register_repository_class)
        @subclass = Class.new(Puppet::RouteManager::Repository) do
            def self.to_s
                "Puppet::RouteManager::Repository::MyTermType"
            end
        end
    end

    it "should set the name of the abstract subclass to be its class constant" do
        @subclass.name.should equal(:my_term_type)
    end

    it "should mark abstract repository types as such" do
        @subclass.should be_abstract_repository
    end

    it "should not allow instances of abstract subclasses to be created" do
        proc { @subclass.new }.should raise_error(Puppet::DevError)
    end
end

