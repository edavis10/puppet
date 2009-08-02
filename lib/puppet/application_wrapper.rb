# A wrapper class that knows how to parse ARGV
# enough to figure out which application we should
# be using and then delegate to that.
require 'puppet/application'

class Puppet::ApplicationWrapper
    def run
        app_name = ARGV.find { |item| item !~ /^-/ }
        unless app = Puppet::Application[app_name]
            raise "Could not find app %s" % app_name
        end

        app.run
    end
end
