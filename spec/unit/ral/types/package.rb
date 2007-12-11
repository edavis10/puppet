#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

require 'puppet/type/package'

describe Puppet::Type::Package do
    it "should have an :installable feature that requires the :install method" do
        Puppet::Type::Package.provider_feature(:installable).methods.should == [:install]
    end

    it "should have an :uninstallable feature that requires the :uninstall method" do
        Puppet::Type::Package.provider_feature(:uninstallable).methods.should == [:uninstall]
    end

    it "should have an :upgradeable feature that requires :update and :latest methods" do
        Puppet::Type::Package.provider_feature(:upgradeable).methods.should == [:update, :latest]
    end

    it "should have a :purgeable feature that requires the :purge latest method" do
        Puppet::Type::Package.provider_feature(:purgeable).methods.should == [:purge]
    end

    it "should have a :versionable feature" do
        Puppet::Type::Package.provider_feature(:versionable).should_not be_nil
    end

    it "should default to being installed" do
        pkg = Puppet::Type::Package.create(:name => "yay")
        pkg.should(:ensure).should == :present
    end

    after { Puppet::Type::Package.clear }
end

describe Puppet::Type::Package, "when validating attributes" do
    [:name, :source, :instance, :status, :adminfile, :responsefile, :configfiles, :category, :platform, :root, :vendor, :description, :allowcdrom].each do |param|
        it "should have a #{param} parameter" do
            Puppet::Type::Package.attrtype(param).should == :param
        end
    end

    it "should have an ensure property" do
        Puppet::Type::Package.attrtype(:ensure).should == :property
    end
end

describe Puppet::Type::Package, "when validating attribute values" do
    before do
        @provider = stub 'provider', :class => Puppet::Type::Package.defaultprovider, :clear => nil
        Puppet::Type::Package.defaultprovider.expects(:new).returns(@provider)
    end

    it "should support :present as a value to :ensure" do
        Puppet::Type::Package.create(:name => "yay", :ensure => :present)
    end

    it "should alias :installed to :present as a value to :ensure" do
        pkg = Puppet::Type::Package.create(:name => "yay", :ensure => :installed)
        pkg.should(:ensure).should == :present
    end

    it "should support :absent as a value to :ensure" do
        Puppet::Type::Package.create(:name => "yay", :ensure => :absent)
    end

    it "should support :purged as a value to :ensure if the provider has the :purgeable feature" do
        @provider.expects(:satisfies?).with(:purgeable).returns(true)
        Puppet::Type::Package.create(:name => "yay", :ensure => :purged)
    end

    it "should not support :purged as a value to :ensure if the provider does not have the :purgeable feature" do
        @provider.expects(:satisfies?).with(:purgeable).returns(false)
        proc { Puppet::Type::Package.create(:name => "yay", :ensure => :purged) }.should raise_error(Puppet::Error)
    end

    it "should support :latest as a value to :ensure if the provider has the :upgradeable feature" do
        @provider.expects(:satisfies?).with(:upgradeable).returns(true)
        Puppet::Type::Package.create(:name => "yay", :ensure => :latest)
    end

    it "should not support :latest as a value to :ensure if the provider does not have the :upgradeable feature" do
        @provider.expects(:satisfies?).with(:upgradeable).returns(false)
        proc { Puppet::Type::Package.create(:name => "yay", :ensure => :latest) }.should raise_error(Puppet::Error)
    end

    it "should support version numbers as a value to :ensure if the provider has the :versionable feature" do
        @provider.expects(:satisfies?).with(:versionable).returns(true)
        Puppet::Type::Package.create(:name => "yay", :ensure => "1.0")
    end

    it "should not support version numbers as a value to :ensure if the provider does not have the :versionable feature" do
        @provider.expects(:satisfies?).with(:versionable).returns(false)
        proc { Puppet::Type::Package.create(:name => "yay", :ensure => "1.0") }.should raise_error(Puppet::Error)
    end

    it "should only accept files and URLs as values to :source" do
        proc { Puppet::Type::Package.create(:name => "yay", :source => "stuff") }.should raise_error(Puppet::Error)
    end

    after { Puppet::Type::Package.clear }
end

module PackageEvaluationTesting
    def setup
        @provider = stub 'provider', :class => Puppet::Type::Package.defaultprovider, :clear => nil, :satisfies? => true, :name => :mock
        Puppet::Type::Package.defaultprovider.stubs(:new).returns(@provider)
        @package = Puppet::Type::Package.create(:name => "yay")

        @configuration = Puppet::Node::Configuration.new
        @configuration.add_resource(@package)
    end

    def setprops(properties)
        @provider.stubs(:properties).returns(properties)
    end

    def teardown
        @configuration.clear(true)
        Puppet::Type::Package.clear
    end
end

describe Puppet::Type::Package, "when it should be purged" do
    include PackageEvaluationTesting

    before { @package[:ensure] = :purged }

    it "should do nothing if it is :purged" do
        @provider.expects(:properties).returns(:ensure => :purged)
        @configuration.apply
    end

    [:absent, :installed, :present, :latest].each do |state|
        it "should purge if it is #{state.to_s}" do
            @provider.stubs(:properties).returns(:ensure => state)
            @provider.expects(:purge)
            @configuration.apply
        end
    end
end

describe Puppet::Type::Package, "when it should be absent" do
    include PackageEvaluationTesting

    before { @package[:ensure] = :absent }

    [:purged, :absent].each do |state|
        it "should do nothing if it is #{state.to_s}" do
            @provider.expects(:properties).returns(:ensure => state)
            @configuration.apply
        end
    end

    [:installed, :present, :latest].each do |state|
        it "should uninstall if it is #{state.to_s}" do
            @provider.stubs(:properties).returns(:ensure => state)
            @provider.expects(:uninstall)
            @configuration.apply
        end
    end
end

describe Puppet::Type::Package, "when it should be present" do
    include PackageEvaluationTesting

    before { @package[:ensure] = :present }

    [:present, :latest, "1.0"].each do |state|
        it "should do nothing if it is #{state.to_s}" do
            @provider.expects(:properties).returns(:ensure => state)
            @configuration.apply
        end
    end

    [:purged, :absent].each do |state|
        it "should install if it is #{state.to_s}" do
            @provider.stubs(:properties).returns(:ensure => state)
            @provider.expects(:install)
            @configuration.apply
        end
    end
end

describe Puppet::Type::Package, "when it should be latest" do
    include PackageEvaluationTesting

    before { @package[:ensure] = :latest }

    [:purged, :absent].each do |state|
        it "should upgrade if it is #{state.to_s}" do
            @provider.stubs(:properties).returns(:ensure => state)
            @provider.expects(:update)
            @configuration.apply
        end
    end

    it "should upgrade if the current version is not equal to the latest version" do
        @provider.stubs(:properties).returns(:ensure => "1.0")
        @provider.stubs(:latest).returns("2.0")
        @provider.expects(:update)
        @configuration.apply
    end

    it "should do nothing if it is equal to the latest version" do
        @provider.stubs(:properties).returns(:ensure => "1.0")
        @provider.stubs(:latest).returns("1.0")
        @provider.expects(:update).never
        @configuration.apply
    end

    it "should do nothing if the provider returns :present as the latest version" do
        @provider.stubs(:properties).returns(:ensure => :present)
        @provider.stubs(:latest).returns("1.0")
        @provider.expects(:update).never
        @configuration.apply
    end
end

describe Puppet::Type::Package, "when it should be a specific version" do
    include PackageEvaluationTesting

    before { @package[:ensure] = "1.0" }

    [:purged, :absent].each do |state|
        it "should install if it is #{state.to_s}" do
            @provider.stubs(:properties).returns(:ensure => state)
            @provider.expects(:install)
            @configuration.apply
        end
    end

    it "should do nothing if the current version is equal to the desired version" do
        @provider.stubs(:properties).returns(:ensure => "1.0")
        @provider.expects(:install).never
        @configuration.apply
    end

    it "should install if the current version is not equal to the specified version" do
        @provider.stubs(:properties).returns(:ensure => "2.0")
        @provider.expects(:install)
        @configuration.apply
    end
end