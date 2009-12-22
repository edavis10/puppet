#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/route_manager/router'

describe "Router Delegator", :shared => true do
    it "should create a request object with the appropriate method name and all of the passed arguments" do
        request = Puppet::RouteManager::Request.new(:router, :find, "me")

        @router.expects(:request).with(@method, "mystuff", :one => :two).returns request

        @repository.stubs(@method)

        @router.send(@method, "mystuff", :one => :two)
    end

    it "should let the :select_repository method choose the repository using the created request if the :select_repository method is available" do
        # Define the method, so our respond_to? hook matches.
        class << @router
            def select_repository(request)
            end
        end

        request = Puppet::RouteManager::Request.new(:router, :find, "me")

        @router.stubs(:request).returns request

        @router.expects(:select_repository).with(request).returns :test_repository

        @router.stubs(:check_authorization)
        @repository.expects(@method)

        @router.send(@method, "me")
    end

    it "should fail if the :select_repository hook does not return a repository name" do
        # Define the method, so our respond_to? hook matches.
        class << @router
            def select_repository(request)
            end
        end

        request = stub 'request', :key => "me", :options => {}

        @router.stubs(:request).returns request

        @router.expects(:select_repository).with(request).returns nil

        lambda { @router.send(@method, "me") }.should raise_error(ArgumentError)
    end

    it "should choose the repository returned by the :repository_class method if no :select_repository method is available" do
        @router.expects(:repository_class).returns :test_repository

        @repository.expects(@method)

        @router.send(@method, "me")
    end

    it "should let the appropriate repository perform the lookup" do
        @repository.expects(@method).with { |r| r.is_a?(Puppet::RouteManager::Request) }
        @router.send(@method, "me")
    end
end

describe "Delegation Authorizer", :shared => true do
    before do
        # So the :respond_to? turns out correctly.
        class << @repository
            def authorized?
            end
        end
    end

    it "should not check authorization if a node name is not provided" do
        @repository.expects(:authorized?).never
        @repository.stubs(@method)

        # The quotes are necessary here, else it looks like a block.
        @request.stubs(:options).returns({})
        @router.send(@method, "/my/key")
    end

    it "should pass the request to the repository's authorization method" do
        @repository.expects(:authorized?).with { |r| r.is_a?(Puppet::RouteManager::Request) }.returns(true)
        @repository.stubs(@method)

        @router.send(@method, "/my/key", :node => "mynode")
    end

    it "should fail if authorization returns false" do
        @repository.expects(:authorized?).returns(false)
        @repository.stubs(@method)
        proc { @router.send(@method, "/my/key", :node => "mynode") }.should raise_error(ArgumentError)
    end

    it "should continue if authorization returns true" do
        @repository.expects(:authorized?).returns(true)
        @repository.stubs(@method)
        @router.send(@method, "/my/key", :node => "mynode")
    end
end

describe Puppet::RouteManager::Router do
    after do
        Puppet::Util::Cacher.expire
    end
    describe "when initializing" do
        # (LAK) I've no idea how to test this, really.
        it "should store a reference to itself before it consumes its options" do
            proc { @router = Puppet::RouteManager::Router.new(Object.new, :testingness, :not_valid_option) }.should raise_error
            Puppet::RouteManager::Router.instance(:testingness).should be_instance_of(Puppet::RouteManager::Router)
            Puppet::RouteManager::Router.instance(:testingness).delete
        end

        it "should keep a reference to the indirecting model" do
            model = mock 'model'
            @router = Puppet::RouteManager::Router.new(model, :myind)
            @router.model.should equal(model)
        end

        it "should set the name" do
            @router = Puppet::RouteManager::Router.new(mock('model'), :myind)
            @router.name.should == :myind
        end

        it "should require routers to have unique names" do
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            proc { Puppet::RouteManager::Router.new(:test) }.should raise_error(ArgumentError)
        end

        it "should extend itself with any specified module" do
            mod = Module.new
            @router = Puppet::RouteManager::Router.new(mock('model'), :test, :extend => mod)
            @router.metaclass.included_modules.should include(mod)
        end

        after do
            @router.delete if defined? @router
        end
    end

    describe "when an instance" do
        before :each do
            @repository_class = mock 'repository_class'
            @repository = mock 'repository'
            @repository_class.stubs(:new).returns(@repository)
            @cache = stub 'cache', :name => "mycache"
            @cache_class = mock 'cache_class'
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :cache_repository).returns(@cache_class)
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :test_repository).returns(@repository_class)

            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            @router.repository_class = :test_repository

            @instance = stub 'instance', :expiration => nil, :expiration= => nil, :name => "whatever"
            @name = :mything

            #@request = stub 'instance', :key => "/my/key", :instance => @instance, :options => {}
            @request = mock 'instance'
        end

        it "should allow setting the ttl" do
            @router.ttl = 300
            @router.ttl.should == 300
        end

        it "should default to the :runinterval setting, converted to an integer, for its ttl" do
            Puppet.settings.expects(:value).returns "1800"
            @router.ttl.should == 1800
        end

        it "should calculate the current expiration by adding the TTL to the current time" do
            @router.stubs(:ttl).returns(100)
            now = Time.now
            Time.stubs(:now).returns now
            @router.expiration.should == (Time.now + 100)
        end

        it "should have a method for creating an router request instance" do
            @router.should respond_to(:request)
        end

        describe "creates a request" do
            it "should create it with its name as the request's router name" do
                Puppet::RouteManager::Request.expects(:new).with { |name, *other| @router.name == name }
                @router.request(:funtest, "yayness")
            end

            it "should require a method and key" do
                Puppet::RouteManager::Request.expects(:new).with { |name, method, key, *other| method == :funtest and key == "yayness" }
                @router.request(:funtest, "yayness")
            end

            it "should support optional arguments" do
                Puppet::RouteManager::Request.expects(:new).with { |name, method, key, other| other == {:one => :two} }
                @router.request(:funtest, "yayness", :one => :two)
            end

            it "should default to the arguments being nil" do
                Puppet::RouteManager::Request.expects(:new).with { |name, method, key, args| args.nil? }
                @router.request(:funtest, "yayness")
            end

            it "should return the request" do
                request = mock 'request'
                Puppet::RouteManager::Request.expects(:new).returns request
                @router.request(:funtest, "yayness").should equal(request)
            end
        end

        describe "and looking for a model instance" do
            before { @method = :find }

            it_should_behave_like "Router Delegator"
            it_should_behave_like "Delegation Authorizer"

            it "should return the results of the delegation" do
                @repository.expects(:find).returns(@instance)
                @router.find("me").should equal(@instance)
            end

            it "should set the expiration date on any instances without one set" do
                @repository.stubs(:find).returns(@instance)

                @router.expects(:expiration).returns :yay

                @instance.expects(:expiration).returns(nil)
                @instance.expects(:expiration=).with(:yay)

                @router.find("/my/key")
            end

            it "should not override an already-set expiration date on returned instances" do
                @repository.stubs(:find).returns(@instance)

                @router.expects(:expiration).never

                @instance.expects(:expiration).returns(:yay)
                @instance.expects(:expiration=).never

                @router.find("/my/key")
            end

            it "should filter the result instance if the repository supports it" do
                @repository.stubs(:find).returns(@instance)
                @repository.stubs(:respond_to?).with(:filter).returns(true)

                @repository.expects(:filter).with(@instance)

                @router.find("/my/key")
            end
            describe "when caching is enabled" do
                before do
                    @router.cache_class = :cache_repository
                    @cache_class.stubs(:new).returns(@cache)

                    @instance.stubs(:expired?).returns false
                end

                it "should first look in the cache for an instance" do
                    @repository.stubs(:find).never
                    @cache.expects(:find).returns @instance

                    @router.find("/my/key")
                end

                it "should not look in the cache if the request specifies not to use the cache" do
                    @repository.expects(:find).returns @instance
                    @cache.expects(:find).never
                    @cache.stubs(:save)

                    @router.find("/my/key", :ignore_cache => true)
                end

                it "should still save to the cache even if the cache is being ignored during readin" do
                    @repository.expects(:find).returns @instance
                    @cache.expects(:save)

                    @router.find("/my/key", :ignore_cache => true)
                end

                it "should only look in the cache if the request specifies not to use the repository" do
                    @repository.expects(:find).never
                    @cache.expects(:find)

                    @router.find("/my/key", :ignore_repository => true)
                end

                it "should use a request to look in the cache for cached objects" do
                    @cache.expects(:find).with { |r| r.method == :find and r.key == "/my/key" }.returns @instance

                    @cache.stubs(:save)

                    @router.find("/my/key")
                end

                it "should return the cached object if it is not expired" do
                    @instance.stubs(:expired?).returns false

                    @cache.stubs(:find).returns @instance
                    @router.find("/my/key").should equal(@instance)
                end

                it "should not fail if the cache fails" do
                    @repository.stubs(:find).returns @instance

                    @cache.expects(:find).raises ArgumentError
                    @cache.stubs(:save)
                    lambda { @router.find("/my/key") }.should_not raise_error
                end

                it "should look in the main repository if the cache fails" do
                    @repository.expects(:find).returns @instance
                    @cache.expects(:find).raises ArgumentError
                    @cache.stubs(:save)
                    @router.find("/my/key").should equal(@instance)
                end

                it "should send a debug log if it is using the cached object" do
                    Puppet.expects(:debug)
                    @cache.stubs(:find).returns @instance

                    @router.find("/my/key")
                end

                it "should not return the cached object if it is expired" do
                    @instance.stubs(:expired?).returns true

                    @cache.stubs(:find).returns @instance
                    @repository.stubs(:find).returns nil
                    @router.find("/my/key").should be_nil
                end

                it "should send an info log if it is using the cached object" do
                    Puppet.expects(:info)
                    @instance.stubs(:expired?).returns true

                    @cache.stubs(:find).returns @instance
                    @repository.stubs(:find).returns nil
                    @router.find("/my/key")
                end

                it "should cache any objects not retrieved from the cache" do
                    @cache.expects(:find).returns nil

                    @repository.expects(:find).returns(@instance)
                    @cache.expects(:save)

                    @router.find("/my/key")
                end

                it "should use a request to look in the cache for cached objects" do
                    @cache.expects(:find).with { |r| r.method == :find and r.key == "/my/key" }.returns nil

                    @repository.stubs(:find).returns(@instance)
                    @cache.stubs(:save)

                    @router.find("/my/key")
                end

                it "should cache the instance using a request with the instance set to the cached object" do
                    @cache.stubs(:find).returns nil

                    @repository.stubs(:find).returns(@instance)

                    @cache.expects(:save).with { |r| r.method == :save and r.instance == @instance }

                    @router.find("/my/key")
                end

                it "should send an info log that the object is being cached" do
                    @cache.stubs(:find).returns nil

                    @repository.stubs(:find).returns(@instance)
                    @cache.stubs(:save)

                    Puppet.expects(:info)

                    @router.find("/my/key")
                end
            end
        end

        describe "and storing a model instance" do
            before { @method = :save }

            it_should_behave_like "Router Delegator"
            it_should_behave_like "Delegation Authorizer"

            it "should return the result of the save" do
                @repository.stubs(:save).returns "foo"
                @router.save(@instance).should == "foo"
            end

            describe "when caching is enabled" do
                before do
                    @router.cache_class = :cache_repository
                    @cache_class.stubs(:new).returns(@cache)

                    @instance.stubs(:expired?).returns false
                end

                it "should return the result of saving to the repository" do
                    request = stub 'request', :instance => @instance, :node => nil

                    @router.expects(:request).returns request

                    @cache.stubs(:save)
                    @repository.stubs(:save).returns @instance
                    @router.save(@instance).should equal(@instance)
                end

                it "should use a request to save the object to the cache" do
                    request = stub 'request', :instance => @instance, :node => nil

                    @router.expects(:request).returns request

                    @cache.expects(:save).with(request)
                    @repository.stubs(:save)
                    @router.save(@instance)
                end

                it "should not save to the cache if the normal save fails" do
                    request = stub 'request', :instance => @instance, :node => nil

                    @router.expects(:request).returns request

                    @cache.expects(:save).never
                    @repository.expects(:save).raises "eh"
                    lambda { @router.save(@instance) }.should raise_error
                end
            end
        end

        describe "and removing a model instance" do
            before { @method = :destroy }

            it_should_behave_like "Router Delegator"
            it_should_behave_like "Delegation Authorizer"

            it "should return the result of removing the instance" do
                @repository.stubs(:destroy).returns "yayness"
                @router.destroy("/my/key").should == "yayness"
            end

            describe "when caching is enabled" do
                before do
                    @router.cache_class = :cache_repository
                    @cache_class.expects(:new).returns(@cache)

                    @instance.stubs(:expired?).returns false
                end

                it "should use a request instance to search in and remove objects from the cache" do
                    destroy = stub 'destroy_request', :key => "/my/key", :node => nil
                    find = stub 'destroy_request', :key => "/my/key", :node => nil

                    @router.expects(:request).with(:destroy, "/my/key").returns destroy
                    @router.expects(:request).with(:find, "/my/key").returns find

                    cached = mock 'cache'

                    @cache.expects(:find).with(find).returns cached
                    @cache.expects(:destroy).with(destroy)

                    @repository.stubs(:destroy)

                    @router.destroy("/my/key")
                end
            end
        end

        describe "and searching for multiple model instances" do
            before { @method = :search }

            it_should_behave_like "Router Delegator"
            it_should_behave_like "Delegation Authorizer"

            it "should set the expiration date on any instances without one set" do
                @repository.stubs(:search).returns([@instance])

                @router.expects(:expiration).returns :yay

                @instance.expects(:expiration).returns(nil)
                @instance.expects(:expiration=).with(:yay)

                @router.search("/my/key")
            end

            it "should not override an already-set expiration date on returned instances" do
                @repository.stubs(:search).returns([@instance])

                @router.expects(:expiration).never

                @instance.expects(:expiration).returns(:yay)
                @instance.expects(:expiration=).never

                @router.search("/my/key")
            end

            it "should return the results of searching in the repository" do
                @repository.expects(:search).returns([@instance])
                @router.search("/my/key").should == [@instance]
            end
        end

        describe "and expiring a model instance" do
            describe "when caching is not enabled" do
                it "should do nothing" do
                    @cache_class.expects(:new).never

                    @router.expire("/my/key")
                end
            end

            describe "when caching is enabled" do
                before do
                    @router.cache_class = :cache_repository
                    @cache_class.expects(:new).returns(@cache)

                    @instance.stubs(:expired?).returns false

                    @cached = stub 'cached', :expiration= => nil, :name => "/my/key"
                end

                it "should use a request to find within the cache" do
                    @cache.expects(:find).with { |r| r.is_a?(Puppet::RouteManager::Request) and r.method == :find }
                    @router.expire("/my/key")
                end

                it "should do nothing if no such instance is cached" do
                    @cache.expects(:find).returns nil

                    @router.expire("/my/key")
                end

                it "should log that it is expiring any found instance" do
                    @cache.expects(:find).returns @cached
                    @cache.stubs(:save)

                    Puppet.expects(:info)

                    @router.expire("/my/key")
                end

                it "should set the cached instance's expiration to a time in the past" do
                    @cache.expects(:find).returns @cached
                    @cache.stubs(:save)

                    @cached.expects(:expiration=).with { |t| t < Time.now }

                    @router.expire("/my/key")
                end

                it "should save the now expired instance back into the cache" do
                    @cache.expects(:find).returns @cached

                    @cached.expects(:expiration=).with { |t| t < Time.now }

                    @cache.expects(:save)

                    @router.expire("/my/key")
                end

                it "should use a request to save the expired resource to the cache" do
                    @cache.expects(:find).returns @cached

                    @cached.expects(:expiration=).with { |t| t < Time.now }

                    @cache.expects(:save).with { |r| r.is_a?(Puppet::RouteManager::Request) and r.instance == @cached and r.method == :save }.returns(@cached)

                    @router.expire("/my/key")
                end
            end
        end

        after :each do
            @router.delete
            Puppet::Util::Cacher.expire
        end
    end


    describe "when managing router instances" do
        it "should allow an router to be retrieved by name" do
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            Puppet::RouteManager::Router.instance(:test).should equal(@router)
        end

        it "should return nil when the named router has not been created" do
            Puppet::RouteManager::Router.instance(:test).should be_nil
        end

        it "should allow an router's model to be retrieved by name" do
            mock_model = mock('model')
            @router = Puppet::RouteManager::Router.new(mock_model, :test)
            Puppet::RouteManager::Router.model(:test).should equal(mock_model)
        end

        it "should return nil when no model matches the requested name" do
            Puppet::RouteManager::Router.model(:test).should be_nil
        end

        after do
            @router.delete if defined? @router
        end
    end

    describe "when routing to the correct the repository class" do
        before do
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            @repository = mock 'repository'
            @repository_class = stub 'repository class', :new => @repository
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :default).returns(@repository_class)
        end

        it "should fail if no repository class can be picked" do
            proc { @router.repository_class }.should raise_error(Puppet::DevError)
        end

        it "should choose the default repository class if one is specified" do
            @router.repository_class = :default
            @router.repository_class.should equal(:default)
        end

        it "should use the provided Puppet setting if told to do so" do
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :my_repository).returns(mock("repository_class2"))
            Puppet.settings.expects(:value).with(:my_setting).returns("my_repository")
            @router.repository_setting = :my_setting
            @router.repository_class.should equal(:my_repository)
        end

        it "should fail if the provided repository class is not valid" do
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :nosuchclass).returns(nil)
            proc { @router.repository_class = :nosuchclass }.should raise_error(ArgumentError)
        end

        after do
            @router.delete if defined? @router
        end
    end

    describe "when specifying the repository class to use" do
        before do
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            @repository = mock 'repository'
            @repository_class = stub 'repository class', :new => @repository
        end

        it "should allow specification of a repository type" do
            @router.should respond_to(:repository_class=)
        end

        it "should fail to redirect if no repository type has been specified" do
            proc { @router.find("blah") }.should raise_error(Puppet::DevError)
        end

        it "should fail when the repository class name is an empty string" do
            proc { @router.repository_class = "" }.should raise_error(ArgumentError)
        end

        it "should fail when the repository class name is nil" do
            proc { @router.repository_class = nil }.should raise_error(ArgumentError)
        end

        it "should fail when the specified repository class cannot be found" do
            Puppet::RouteManager::Repository.expects(:repository_class).with(:test, :foo).returns(nil)
            proc { @router.repository_class = :foo }.should raise_error(ArgumentError)
        end

        it "should select the specified repository class if a repository class name is provided" do
            Puppet::RouteManager::Repository.expects(:repository_class).with(:test, :foo).returns(@repository_class)
            @router.repository(:foo).should equal(@repository)
        end

        it "should use the configured repository class if no repository name is specified" do
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :foo).returns(@repository_class)
            @router.repository_class = :foo
            @router.repository().should equal(@repository)
        end

        after do
            @router.delete if defined? @router
        end
    end

    describe "when managing repository instances" do
        before do
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            @repository = mock 'repository'
            @repository_class = mock 'repository class'
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :foo).returns(@repository_class)
        end

        it "should create an instance of the chosen repository class" do
            @repository_class.stubs(:new).returns(@repository)
            @router.repository(:foo).should equal(@repository)
        end

        # Make sure it caches the repository.
        it "should return the same repository instance each time for a given name" do
            @repository_class.stubs(:new).returns(@repository)
            @router.repository(:foo).should equal(@repository)
            @router.repository(:foo).should equal(@repository)
        end

        it "should not create a repository instance until one is actually needed" do
            Puppet::RouteManager.expects(:repository).never
            router = Puppet::RouteManager::Router.new(mock('model'), :lazytest)
        end

        after do
            @router.delete
        end
    end

    describe "when deciding whether to cache" do
        before do
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            @repository = mock 'repository'
            @repository_class = mock 'repository class'
            @repository_class.stubs(:new).returns(@repository)
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :foo).returns(@repository_class)
            @router.repository_class = :foo
        end

        it "should provide a method for setting the cache repository class" do
            @router.should respond_to(:cache_class=)
        end

        it "should fail to cache if no cache type has been specified" do
            proc { @router.cache }.should raise_error(Puppet::DevError)
        end

        it "should fail to set the cache class when the cache class name is an empty string" do
            proc { @router.cache_class = "" }.should raise_error(ArgumentError)
        end

        it "should allow resetting the cache_class to nil" do
            @router.cache_class = nil
            @router.cache_class.should be_nil
        end

        it "should fail to set the cache class when the specified cache class cannot be found" do
            Puppet::RouteManager::Repository.expects(:repository_class).with(:test, :foo).returns(nil)
            proc { @router.cache_class = :foo }.should raise_error(ArgumentError)
        end

        after do
            @router.delete
        end
    end

    describe "when using a cache" do
        before :each do
            Puppet.settings.stubs(:value).with("test_repository").returns("test_repository")
            @repository_class = mock 'repository_class'
            @repository = mock 'repository'
            @repository_class.stubs(:new).returns(@repository)
            @cache = mock 'cache'
            @cache_class = mock 'cache_class'
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :cache_repository).returns(@cache_class)
            Puppet::RouteManager::Repository.stubs(:repository_class).with(:test, :test_repository).returns(@repository_class)
            @router = Puppet::RouteManager::Router.new(mock('model'), :test)
            @router.repository_class = :test_repository
        end

        describe "and managing the cache repository" do
            it "should not create a cache repository at initialization" do
                # This is weird, because all of the code is in the setup.  If we got
                # new() called on the cache class, we'd get an exception here.
            end

            it "should reuse the cache repository" do
                @cache_class.expects(:new).returns(@cache)
                Puppet.settings.stubs(:value).with("test_cache").returns("cache_repository")
                @router.cache_class = :cache_repository
                @router.cache.should equal(@cache)
                @router.cache.should equal(@cache)
            end
        end

        describe "and saving" do
        end

        describe "and finding" do
        end

        after :each do
            @router.delete
        end
    end
end
