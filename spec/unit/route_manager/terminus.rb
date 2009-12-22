#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'
require 'puppet/defaults'
require 'puppet/route_manager'
require 'puppet/route_manager/file'

describe Puppet::RouteManager::Terminus do
    before :each do
        Puppet::RouteManager::Terminus.stubs(:register_terminus_class)
        @router = stub 'router', :name => :my_stuff, :register_terminus_type => nil
        Puppet::RouteManager::Router.stubs(:instance).with(:my_stuff).returns(@router)
        @abstract_terminus = Class.new(Puppet::RouteManager::Terminus) do
            def self.to_s
                "Testing::Abstract"
            end
        end
        @terminus_class = Class.new(@abstract_terminus) do
            def self.to_s
                "MyStuff::TermType"
            end
        end
        @terminus = @terminus_class.new
    end

    describe Puppet::RouteManager::Terminus do

        it "should provide a method for setting terminus class documentation" do
            @terminus_class.should respond_to(:desc)
        end

        it "should support a class-level name attribute" do
            @terminus_class.should respond_to(:name)
        end

        it "should support a class-level router attribute" do
            @terminus_class.should respond_to(:router)
        end

        it "should support a class-level terminus-type attribute" do
            @terminus_class.should respond_to(:terminus_type)
        end

        it "should support a class-level model attribute" do
            @terminus_class.should respond_to(:model)
        end

        it "should accept router instances as its router" do
            router = stub 'router', :is_a? => true, :register_terminus_type => nil
            proc { @terminus_class.router = router }.should_not raise_error
            @terminus_class.router.should equal(router)
        end

        it "should look up router instances when only a name has been provided" do
            router = mock 'router'
            Puppet::RouteManager::Router.expects(:instance).with(:myind).returns(router)
            @terminus_class.router = :myind
            @terminus_class.router.should equal(router)
        end

        it "should fail when provided a name that does not resolve to an router" do
            Puppet::RouteManager::Router.expects(:instance).with(:myind).returns(nil)
            proc { @terminus_class.router = :myind }.should raise_error(ArgumentError)

            # It shouldn't overwrite our existing one (or, more normally, it shouldn't set
            # anything).
            @terminus_class.router.should equal(@router)
        end
    end

    describe Puppet::RouteManager::Terminus, " when creating terminus classes" do
        it "should associate the subclass with an router based on the subclass constant" do
            @terminus.router.should equal(@router)
        end

        it "should set the subclass's type to the abstract terminus name" do
            @terminus.terminus_type.should == :abstract
        end

        it "should set the subclass's name to the router name" do
            @terminus.name.should == :term_type
        end

        it "should set the subclass's model to the router model" do
            @router.expects(:model).returns :yay
            @terminus.model.should == :yay
        end
    end

    describe Puppet::RouteManager::Terminus, " when a terminus instance" do

        it "should return the class's name as its name" do
            @terminus.name.should == :term_type
        end

        it "should return the class's router as its router" do
            @terminus.router.should equal(@router)
        end

        it "should set the instances's type to the abstract terminus type's name" do
            @terminus.terminus_type.should == :abstract
        end

        it "should set the instances's model to the router's model" do
            @router.expects(:model).returns :yay
            @terminus.model.should == :yay
        end
    end
end

# LAK: This could reasonably be in the Router instances, too.  It doesn't make
# a whole heckuva lot of difference, except that with the instance loading in
# the Terminus base class, we have to have a check to see if we're already
# instance-loading a given terminus class type.
describe Puppet::RouteManager::Terminus, " when managing terminus classes" do
    it "should provide a method for registering terminus classes" do
        Puppet::RouteManager::Terminus.should respond_to(:register_terminus_class)
    end

    it "should provide a method for returning terminus classes by name and type" do
        terminus = stub 'terminus_type', :name => :abstract, :router_name => :whatever
        Puppet::RouteManager::Terminus.register_terminus_class(terminus)
        Puppet::RouteManager::Terminus.terminus_class(:whatever, :abstract).should equal(terminus)
    end

    it "should set up autoloading for any terminus class types requested" do
        Puppet::RouteManager::Terminus.expects(:instance_load).with(:test2, "puppet/route_manager/test2")
        Puppet::RouteManager::Terminus.terminus_class(:test2, :whatever)
    end

    it "should load terminus classes that are not found" do
        # Set up instance loading; it would normally happen automatically
        Puppet::RouteManager::Terminus.instance_load :test1, "puppet/route_manager/test1"

        Puppet::RouteManager::Terminus.instance_loader(:test1).expects(:load).with(:yay)
        Puppet::RouteManager::Terminus.terminus_class(:test1, :yay)
    end

    it "should fail when no router can be found" do
        Puppet::RouteManager::Router.expects(:instance).with(:my_router).returns(nil)

        @abstract_terminus = Class.new(Puppet::RouteManager::Terminus) do
            def self.to_s
                "Abstract"
            end
        end
        proc {
            @terminus = Class.new(@abstract_terminus) do
                def self.to_s
                    "MyRouter::TestType"
                end
            end
        }.should raise_error(ArgumentError)
    end

    it "should register the terminus class with the terminus base class" do
        Puppet::RouteManager::Terminus.expects(:register_terminus_class).with do |type|
            type.router_name == :my_router and type.name == :test_terminus
        end
        @router = stub 'router', :name => :my_router, :register_terminus_type => nil
        Puppet::RouteManager::Router.expects(:instance).with(:my_router).returns(@router)

        @abstract_terminus = Class.new(Puppet::RouteManager::Terminus) do
            def self.to_s
                "Abstract"
            end
        end

        @terminus = Class.new(@abstract_terminus) do
            def self.to_s
                "MyRouter::TestTerminus"
            end
        end
    end
end

describe Puppet::RouteManager::Terminus, " when parsing class constants for router and terminus names" do
    before do
        @subclass = mock 'subclass'
        @subclass.stubs(:to_s).returns("TestInd::OneTwo")
        @subclass.stubs(:mark_as_abstract_terminus)
        Puppet::RouteManager::Terminus.stubs(:register_terminus_class)
    end

    it "should fail when anonymous classes are used" do
        proc { Puppet::RouteManager::Terminus.inherited(Class.new) }.should raise_error(Puppet::DevError)
    end

    it "should use the last term in the constant for the terminus class name" do
        @subclass.expects(:name=).with(:one_two)
        @subclass.stubs(:router=)
        Puppet::RouteManager::Terminus.inherited(@subclass)
    end

    it "should convert the terminus name to a downcased symbol" do
        @subclass.expects(:name=).with(:one_two)
        @subclass.stubs(:router=)
        Puppet::RouteManager::Terminus.inherited(@subclass)
    end

    it "should use the second to last term in the constant for the router name" do
        @subclass.expects(:router=).with(:test_ind)
        @subclass.stubs(:name=)
        @subclass.stubs(:terminus_type=)
        Puppet::RouteManager::File.inherited(@subclass)
    end

    it "should convert the router name to a downcased symbol" do
        @subclass.expects(:router=).with(:test_ind)
        @subclass.stubs(:name=)
        @subclass.stubs(:terminus_type=)
        Puppet::RouteManager::File.inherited(@subclass)
    end

    it "should convert camel case to lower case with underscores as word separators" do
        @subclass.expects(:name=).with(:one_two)
        @subclass.stubs(:router=)

        Puppet::RouteManager::Terminus.inherited(@subclass)
    end
end

describe Puppet::RouteManager::Terminus, " when creating terminus class types" do
    before do
        Puppet::RouteManager::Terminus.stubs(:register_terminus_class)
        @subclass = Class.new(Puppet::RouteManager::Terminus) do
            def self.to_s
                "Puppet::RouteManager::Terminus::MyTermType"
            end
        end
    end

    it "should set the name of the abstract subclass to be its class constant" do
        @subclass.name.should equal(:my_term_type)
    end

    it "should mark abstract terminus types as such" do
        @subclass.should be_abstract_terminus
    end

    it "should not allow instances of abstract subclasses to be created" do
        proc { @subclass.new }.should raise_error(Puppet::DevError)
    end
end

