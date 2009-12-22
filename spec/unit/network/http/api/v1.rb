#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

require 'puppet/network/http/api/v1'

class V1RestApiTester
    include Puppet::Network::HTTP::API::V1
end

describe Puppet::Network::HTTP::API::V1 do
    before do
        @tester = V1RestApiTester.new
    end

    it "should be able to convert a URI into a request" do
        @tester.should respond_to(:uri2router)
    end

    it "should be able to convert a request into a URI" do
        @tester.should respond_to(:router2uri)
    end

    describe "when converting a URI into a request" do
        before do
            @tester.stubs(:handler).returns "foo"
        end

        it "should require the http method, the URI, and the query parameters" do
            # Not a terribly useful test, but an important statement for the spec
            lambda { @tester.uri2router("/foo") }.should raise_error(ArgumentError)
        end

        it "should use the first field of the URI as the environment" do
            @tester.uri2router("GET", "/env/foo/bar", {}).environment.should == Puppet::Node::Environment.new("env")
        end

        it "should fail if the environment is not alphanumeric" do
            lambda { @tester.uri2router("GET", "/env ness/foo/bar", {}) }.should raise_error(ArgumentError)
        end

        it "should use the environment from the URI even if one is specified in the parameters" do
            @tester.uri2router("GET", "/env/foo/bar", {:environment => "otherenv"}).environment.should == Puppet::Node::Environment.new("env")
        end

        it "should use the second field of the URI as the router name" do
            @tester.uri2router("GET", "/env/foo/bar", {}).router_name.should == :foo
        end

        it "should fail if the router name is not alphanumeric" do
            lambda { @tester.uri2router("GET", "/env/foo ness/bar", {}) }.should raise_error(ArgumentError)
        end

        it "should use the remainder of the URI as the router key" do
            @tester.uri2router("GET", "/env/foo/bar", {}).key.should == "bar"
        end

        it "should support the router key being a /-separated file path" do
            @tester.uri2router("GET", "/env/foo/bee/baz/bomb", {}).key.should == "bee/baz/bomb"
        end

        it "should fail if no router key is specified" do
            lambda { @tester.uri2router("GET", "/env/foo/", {}) }.should raise_error(ArgumentError)
            lambda { @tester.uri2router("GET", "/env/foo", {}) }.should raise_error(ArgumentError)
        end

        it "should choose 'find' as the router method if the http method is a GET and the router name is singular" do
            @tester.uri2router("GET", "/env/foo/bar", {}).method.should == :find
        end

        it "should choose 'search' as the router method if the http method is a GET and the router name is plural" do
            @tester.uri2router("GET", "/env/foos/bar", {}).method.should == :search
        end

        it "should choose 'delete' as the router method if the http method is a DELETE and the router name is singular" do
            @tester.uri2router("DELETE", "/env/foo/bar", {}).method.should == :destroy
        end

        it "should choose 'save' as the router method if the http method is a PUT and the router name is singular" do
            @tester.uri2router("PUT", "/env/foo/bar", {}).method.should == :save
        end

        it "should fail if an router method cannot be picked" do
            lambda { @tester.uri2router("UPDATE", "/env/foo/bar", {}) }.should raise_error(ArgumentError)
        end

        it "should URI unescape the router key" do
            escaped = URI.escape("foo bar")
            @tester.uri2router("GET", "/env/foo/#{escaped}", {}).key.should == "foo bar"
        end
    end

    describe "when converting a request into a URI" do
        before do
            @request = Puppet::RouteManager::Request.new(:foo, :find, "with spaces", :foo => :bar, :environment => "myenv")
        end

        it "should use the environment as the first field of the URI" do
            @tester.router2uri(@request).split("/")[1].should == "myenv"
        end

        it "should use the router as the second field of the URI" do
            @tester.router2uri(@request).split("/")[2].should == "foo"
        end

        it "should pluralize the router name if the method is 'search'" do
            @request.stubs(:method).returns :search
            @tester.router2uri(@request).split("/")[2].should == "foos"
        end

        it "should use the escaped key as the remainder of the URI" do
            escaped = URI.escape("with spaces")
            @tester.router2uri(@request).split("/")[3].sub(/\?.+/, '').should == escaped
        end

        it "should add the query string to the URI" do
            @request.expects(:query_string).returns "?query"
            @tester.router2uri(@request).should =~ /\?query$/
        end
    end

end
