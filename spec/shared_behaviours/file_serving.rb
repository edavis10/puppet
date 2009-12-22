#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-10-18.
#  Copyright (c) 2007. All rights reserved.

describe "Puppet::FileServing::Files", :shared => true do
    it "should use the rest repository when the 'puppet' URI scheme is used and a host name is present" do
        uri = "puppet://myhost/fakemod/my/file"

        # It appears that the mocking somehow interferes with the caching subsystem.
        # This mock somehow causes another repository to get generated.
        term = @router.repository(:rest)
        @router.stubs(:repository).with(:rest).returns term
        term.expects(:find)
        @test_class.find(uri)
    end

    it "should use the rest repository when the 'puppet' URI scheme is used, no host name is present, and the process name is not 'puppet'" do
        uri = "puppet:///fakemod/my/file"
        Puppet.settings.stubs(:value).returns "foo"
        Puppet.settings.stubs(:value).with(:name).returns("puppetd")
        Puppet.settings.stubs(:value).with(:modulepath).returns("")
        @router.repository(:rest).expects(:find)
        @test_class.find(uri)
    end

    it "should use the file_server repository when the 'puppet' URI scheme is used, no host name is present, and the process name is 'puppet'" do
        uri = "puppet:///fakemod/my/file"
        Puppet::Node::Environment.stubs(:new).returns(stub("env", :name => "testing", :module => nil))
        Puppet.settings.stubs(:value).returns ""
        Puppet.settings.stubs(:value).with(:name).returns("puppet")
        Puppet.settings.stubs(:value).with(:fileserverconfig).returns("/whatever")
        @router.repository(:file_server).expects(:find)
        @router.repository(:file_server).stubs(:authorized?).returns(true)
        @test_class.find(uri)
    end

    it "should use the file repository when the 'file' URI scheme is used" do
        uri = "file:///fakemod/my/file"
        @router.repository(:file).expects(:find)
        @test_class.find(uri)
    end

    it "should use the file repository when a fully qualified path is provided" do
        uri = "/fakemod/my/file"
        @router.repository(:file).expects(:find)
        @test_class.find(uri)
    end

    it "should use the configuration to test whether the request is allowed" do
        uri = "fakemod/my/file"
        mount = mock 'mount'
        config = stub 'configuration', :split_path => [mount, "eh"]
        @router.repository(:file_server).stubs(:configuration).returns config

        @router.repository(:file_server).expects(:find)
        mount.expects(:allowed?).returns(true)
        @test_class.find(uri, :node => "foo", :ip => "bar")
    end
end
