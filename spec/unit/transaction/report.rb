#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/transaction/report'

describe Puppet::Transaction::Report do
    it "should set its host name to the certname" do
        Puppet.settings.expects(:value).with(:certname).returns "myhost"
        Puppet::Transaction::Report.new.host.should == "myhost"
    end

    describe "when accepting logs" do
        before do
            @report = Puppet::Transaction::Report.new
        end

        it "should add new logs to the log list" do
            @report << "log"
            @report.logs[-1].should == "log"
        end

        it "should return self" do
            r = @report << "log"
            r.should equal(@report)
        end
    end

    describe "when using the indirector" do
        it "should redirect :find to the indirection" do
            @indirection = stub 'indirection', :name => :report
            Puppet::Transaction::Report.stubs(:indirection).returns(@indirection)
            @indirection.expects(:find)
            Puppet::Transaction::Report.find(:report)
        end

        it "should redirect :save to the indirection" do
            Facter.stubs(:value).returns("eh")
            @indirection = stub 'indirection', :name => :report
            Puppet::Transaction::Report.stubs(:indirection).returns(@indirection)
            report = Puppet::Transaction::Report.new
            @indirection.expects(:save)
            report.save
        end

        it "should default to the 'processor' terminus" do
            Puppet::Transaction::Report.indirection.terminus_class.should == :processor
        end

        it "should delegate its name attribute to its host method" do
            report = Puppet::Transaction::Report.new
            report.expects(:host).returns "me"
            report.name.should == "me"
        end

        after do
            Puppet::Util::Cacher.expire
        end
    end
end
