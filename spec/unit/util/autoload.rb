#!/usr/bin/env ruby

Dir.chdir(File.dirname(__FILE__)) { (s = lambda { |f| File.exist?(f) ? require(f) : Dir.chdir("..") { s.call(f) } }).call("spec/spec_helper.rb") }

require 'puppet/util/autoload'

describe Puppet::Util::Autoload do
    before do
        @autoload = Puppet::Util::Autoload.new("foo", "tmp")

        @autoload.stubs(:eachdir).yields "/my/dir"
    end

    it "should include its FileCache module" do
        Puppet::Util::Autoload.ancestors.should be_include(Puppet::Util::Autoload::FileCache)
    end

    describe "when loading a file" do
        [RuntimeError, LoadError, SyntaxError].each do |error|
            it "should not die an if a #{error.to_s} exception is thrown" do
                @autoload.stubs(:file_exist?).returns true

                Kernel.expects(:load).raises error

                lambda { @autoload.load("foo") }.should_not raise_error
            end
        end

        it "should skip files that it knows are missing" do
            @autoload.expects(:missing_file?).returns true
            @autoload.expects(:eachdir).never

            @autoload.load("foo")
        end
    end

    describe "when loading all files" do
        before do
            Dir.stubs(:glob).returns "file.rb"
        end

        [RuntimeError, LoadError, SyntaxError].each do |error|
            it "should not die an if a #{error.to_s} exception is thrown" do
                Kernel.expects(:require).raises error

                lambda { @autoload.loadall }.should_not raise_error
            end
        end
    end
end
