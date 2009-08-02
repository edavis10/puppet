#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'

require 'puppet/application_wrapper'

describe Puppet::ApplicationWrapper do
    before do
        @wrapper = Puppet::ApplicationWrapper.new
        @old_argv = ARGV.dup
    end

    after do
        ARGV.clear
        @old_argv.each { |a| ARGV << a }
    end

    it "should look for an application named after the first non-option in ARGV" do
        ARGV.clear
        ARGV << "myapp"

        app = mock 'app'
        Puppet::Application.expects(:[]).with("myapp").returns app

        app.expects(:run)

        @wrapper.run
    end
end
