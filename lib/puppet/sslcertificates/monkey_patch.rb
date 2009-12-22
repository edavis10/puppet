# This is the file that we use to add router to all the SSL Certificate classes.

require 'puppet/route_manager'

OpenSSL::PKey::RSA.extend Puppet::RouteManager
OpenSSL::PKey::RSA.routes :ssl_rsa, :repository_class => :file
